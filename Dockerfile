# syntax=docker/dockerfile:1

ARG CONTAINER_VERSION
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_VERSION
ARG NODE_IMAGE_VERSION=24-trixie-slim
ARG NPM_VERSION=11.12.1

FROM public.ecr.aws/docker/library/node:${NODE_IMAGE_VERSION} AS base
ARG NPM_VERSION
RUN npm install -g npm@${NPM_VERSION}

FROM base AS compile-typescript-stage

WORKDIR /root

COPY \
  package.json \
  package-lock.json \
  tsconfig.json \
  ./
RUN npm ci && npx tsc --version
COPY /src/*.ts src/
RUN npx tsc
RUN grep -l "#!" dist/*.js | xargs chmod a+x

FROM base AS optional-release-stage

# This stage is optional and will only be executed if the FOUNDRY_RELEASE_URL or
# FOUNDRY_USERNAME and FOUNDRY_PASSWORD secrets are provided.  It will download
# and extract the Foundry VTT release for inclusion in the final stage.

ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_VERSION

RUN test -n "${FOUNDRY_VERSION}" || { echo "ERROR: FOUNDRY_VERSION must be passed as --build-arg"; exit 1; }

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

RUN \
  --mount=type=secret,id=foundry_username,required=false \
  --mount=type=secret,id=foundry_password,required=false \
  npm ci --omit=dev && \
  if [ -f /run/secrets/foundry_username ] && [ -f /run/secrets/foundry_password ]; then \
  ./authenticate.js "$(cat /run/secrets/foundry_username)" "$(cat /run/secrets/foundry_password)" cookiejar.json && \
  presigned_url=$(./get_release_url.js --retry 5 cookiejar.json "${FOUNDRY_VERSION}") && \
  DOWNLOAD_URL="${presigned_url}"; \
  elif [ -n "${FOUNDRY_RELEASE_URL}" ]; then \
  DOWNLOAD_URL="${FOUNDRY_RELEASE_URL}"; \
  else \
  echo "No valid credentials or pre-signed URL provided. Skipping pre-installation."; \
  fi && \
  if [ -n "${DOWNLOAD_URL}" ]; then \
  apt-get update && apt-get install -y unzip wget && \
  wget -O ${ARCHIVE} "${DOWNLOAD_URL}" && \
  mkdir -p "dist/resources/app" && \
  unzip -d "dist/resources/app" ${ARCHIVE}; \
  fi

FROM base AS final-stage

ARG CONTAINER_VERSION
ARG FOUNDRY_VERSION
ARG TARGETPLATFORM

RUN test -n "${CONTAINER_VERSION}" || { echo "ERROR: CONTAINER_VERSION must be passed as --build-arg"; exit 1; } ; \
    test -n "${FOUNDRY_VERSION}" || { echo "ERROR: FOUNDRY_VERSION must be passed as --build-arg"; exit 1; }

LABEL com.foundryvtt.version=${FOUNDRY_VERSION}
LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.vendor="Geekpad"

ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}
ENV HOME=/home/node

WORKDIR $HOME

COPY --from=optional-release-stage /root/dist/ .
COPY --from=compile-typescript-stage /root/dist/ .
COPY \
  package.json \
  package-lock.json \
  src/backoff.sh \
  src/check_health.sh \
  src/entrypoint.sh \
  src/launcher.sh \
  src/logging.sh \
  ./
RUN mkdir -p resources /data \
  && chmod a+rx /home/node \
  && chmod a+rwx resources /data \
  && apt-get update && apt-get install -y \
  curl \
  file \
  jq \
  patch \
  sed \
  tzdata \
  unzip \
  && rm -rf /var/lib/apt/lists/* \
  && npm ci --omit=dev && echo ${CONTAINER_VERSION} > image_version.txt \
  && npm uninstall -g npm \
  && rm -rf /usr/local/lib/node_modules/npm

VOLUME ["/data"]
# HTTP Server
EXPOSE 30000/tcp
# TURN Server
# Not exposing TURN ports due to bug in Docker.
# See: https://github.com/moby/moby/issues/11185
# EXPOSE 33478/udp
# EXPOSE 49152-65535/udp

USER node
ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.mjs", "--port=30000", "--headless", "--noupdate",\
  "--dataPath=/data"]
HEALTHCHECK --start-period=3m --interval=30s --timeout=5s CMD ./check_health.sh
