ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_VERSION=13.332
ARG NODE_IMAGE_VERSION=20-bookworm-slim
ARG VERSION

FROM node:${NODE_IMAGE_VERSION} AS compile-typescript-stage

WORKDIR /root

COPY \
  package.json \
  package-lock.json \
  tsconfig.json \
  ./
RUN npm install && npm install --global typescript
COPY /src/*.ts src/
RUN tsc
RUN grep -l "#!" dist/*.js | xargs chmod a+x

FROM node:${NODE_IMAGE_VERSION} AS optional-release-stage

ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_VERSION
ENV ARCHIVE="foundryvtt-${FOUNDRY_VERSION}.zip"

WORKDIR /root
COPY --from=compile-typescript-stage \
  /root/package.json \
  /root/package-lock.json \
  /root/dist/authenticate.js \
  /root/dist/get_release_url.js \
  /root/dist/logging.js \
  ./
# .placeholder file to mitigate https://github.com/moby/moby/issues/37965
RUN mkdir dist && touch dist/.placeholder
RUN --mount=type=secret,id=foundry_credentials,required=false \
  npm install classic-level && \
  if [ -f /run/secrets/foundry_credentials ]; then \
  # Extract credentials from JSON
  apt-get update && apt-get install -y jq && \
  FOUNDRY_USERNAME=$(jq -r '.foundry_username // empty' /run/secrets/foundry_credentials) && \
  FOUNDRY_PASSWORD=$(jq -r '.foundry_password // empty' /run/secrets/foundry_credentials); \
  fi && \
  if [ -n "${FOUNDRY_USERNAME}" ] && [ -n "${FOUNDRY_PASSWORD}" ]; then \
  # Authenticate using credentials and get the pre-signed URL
  ./authenticate.js "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" cookiejar.json && \
  presigned_url=$(./get_release_url.js --retry 5 cookiejar.json "${FOUNDRY_VERSION}") && \
  DOWNLOAD_URL="${presigned_url}"; \
  elif [ -n "${FOUNDRY_RELEASE_URL}" ]; then \
  # Use pre-signed URL
  DOWNLOAD_URL="${FOUNDRY_RELEASE_URL}"; \
  else \
  echo "No valid credentials or pre-signed URL provided. Skipping pre-installation."; \
  fi && \
  if [ -n "${DOWNLOAD_URL}" ]; then \
  apt-get install -y unzip wget && \
  wget -O ${ARCHIVE} "${DOWNLOAD_URL}" && \
  unzip -d dist ${ARCHIVE} 'resources/*'; \
  fi

FROM node:${NODE_IMAGE_VERSION} AS final-stage

ARG FOUNDRY_UID=421
ARG FOUNDRY_VERSION
ARG TARGETPLATFORM
ARG VERSION

LABEL com.foundryvtt.version=${FOUNDRY_VERSION}
LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.vendor="Geekpad"

ENV FOUNDRY_HOME="/home/foundry"
ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}

WORKDIR ${FOUNDRY_HOME}

COPY --from=optional-release-stage /root/dist/ .
COPY --from=compile-typescript-stage /root/dist/ .
COPY \
  package.json \
  package-lock.json \
  src/check_health.sh \
  src/entrypoint.sh \
  src/launcher.sh \
  src/logging.sh \
  ./
RUN addgroup --system --gid ${FOUNDRY_UID} foundry \
  && adduser --system --uid ${FOUNDRY_UID} --ingroup foundry foundry \
  && apt-get update && apt-get install -y \
  curl \
  file \
  gosu \
  jq \
  sed \
  tzdata \
  unzip \
  && rm -rf /var/lib/apt/lists/* \
  && npm install && echo ${VERSION} > image_version.txt

VOLUME ["/data"]
# HTTP Server
EXPOSE 30000/TCP
# TURN Server
# Not exposing TURN ports due to bug in Docker.
# See: https://github.com/moby/moby/issues/11185
# EXPOSE 33478/UDP
# EXPOSE 49152-65535/UDP

ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.mjs", "--port=30000", "--headless", "--noupdate",\
  "--dataPath=/data"]
HEALTHCHECK --start-period=3m --interval=30s --timeout=5s CMD ./check_health.sh
