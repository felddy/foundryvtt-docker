ARG CREATED_TIMESTAMP=unspecified
ARG FOUNDRY_PASSWORD
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_USERNAME
ARG FOUNDRY_VERSION=0.7.3
ARG GIT_COMMIT=unspecified
ARG GIT_REMOTE=unspecified
ARG VERSION

FROM node:12-alpine as optional-release-stage

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

FROM node:12-alpine as final-stage

ARG CREATED_TIMESTAMP=unspecified
ARG FOUNDRY_UID=421
ARG FOUNDRY_VERSION
ARG GIT_COMMIT
ARG GIT_REMOTE
ARG TARGETPLATFORM
ARG VERSION

LABEL com.foundryvtt.version=${FOUNDRY_VERSION}
LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.created=${CREATED_TIMESTAMP}
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.revision=${GIT_COMMIT}
LABEL org.opencontainers.image.source=${GIT_REMOTE}
LABEL org.opencontainers.image.title="Foundry Virtual Tabletop"
LABEL org.opencontainers.image.vendor="Geekpad"
LABEL org.opencontainers.image.version=${VERSION}

ENV FOUNDRY_HOME="/home/foundry"
ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}

WORKDIR ${FOUNDRY_HOME}

COPY --from=optional-release-stage /root/dist/ .
COPY \
  src/authenticate.js \
  src/entrypoint.sh \
  src/get_license.js \
  src/get_release_url.js \
  src/launcher.sh \
  src/logging.js \
  src/logging.sh \
  src/package.json \
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
EXPOSE 30000/TCP

ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.js", "--port=30000", "--headless", "--dataPath=/data"]
HEALTHCHECK --start-period=3m --interval=30s --timeout=5s \
  CMD /usr/bin/curl --cookie-jar healthcheck-cookiejar.txt \
  --cookie healthcheck-cookiejar.txt --fail --silent \
  http://localhost:30000/api/status || exit 1
