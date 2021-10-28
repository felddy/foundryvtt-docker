ARG FOUNDRY_PASSWORD
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_USERNAME
ARG FOUNDRY_VERSION=0.8.9
ARG VERSION

FROM node:17-alpine as optional-release-stage

ARG FOUNDRY_PASSWORD
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_USERNAME
ARG FOUNDRY_VERSION
ENV ARCHIVE="foundryvtt-${FOUNDRY_VERSION}.zip"

WORKDIR /root
COPY \
  src/authenticate.js \
  src/get_release_url.js \
  src/logging.js \
  src/package.json \
  ./
# .placeholder file to mitigate https://github.com/moby/moby/issues/37965
RUN mkdir dist && touch dist/.placeholder
RUN \
  if [ -n "${FOUNDRY_USERNAME}" ] && [ -n "${FOUNDRY_PASSWORD}" ]; then \
  npm install && \
  ./authenticate.js "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" cookiejar.json && \
  s3_url=$(./get_release_url.js cookiejar.json "${FOUNDRY_VERSION}") && \
  wget -O ${ARCHIVE} "${s3_url}" && \
  unzip -d dist ${ARCHIVE} 'resources/*'; \
  elif [ -n "${FOUNDRY_RELEASE_URL}" ]; then \
  wget -O ${ARCHIVE} "${FOUNDRY_RELEASE_URL}" && \
  unzip -d dist ${ARCHIVE} 'resources/*'; \
  fi

FROM node:17-alpine as final-stage

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
COPY \
  src/authenticate.js \
  src/check_health.sh \
  src/entrypoint.sh \
  src/get_license.js \
  src/get_release_url.js \
  src/launcher.sh \
  src/logging.js \
  src/logging.sh \
  src/package.json \
  src/set_options.js \
  src/set_password.js \
  ./
RUN addgroup --system --gid ${FOUNDRY_UID} foundry \
  && adduser --system --uid ${FOUNDRY_UID} --ingroup foundry foundry \
  && apk --update --no-cache add \
  curl \
  jq \
  sed \
  su-exec \
  tzdata \
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
CMD ["resources/app/main.js", "--port=30000", "--headless", "--noupdate",\
  "--dataPath=/data"]
HEALTHCHECK --start-period=3m --interval=30s --timeout=5s CMD ./check_health.sh
