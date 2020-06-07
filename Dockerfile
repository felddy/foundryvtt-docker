ARG FOUNDRY_VERSION=0.6.2
ARG GIT_COMMIT=unspecified
ARG GIT_REMOTE=unspecified
ARG VERSION

FROM node:12-alpine

ARG FOUNDRY_UID=421
ARG FOUNDRY_VERSION
ARG GIT_COMMIT
ARG GIT_REMOTE
ARG TARGETPLATFORM
ARG VERSION

LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.licenses="CC0-1.0"
LABEL org.opencontainers.image.revision=${GIT_COMMIT}
LABEL org.opencontainers.image.source=${GIT_REMOTE}
LABEL org.opencontainers.image.title="FoundryVTT"
LABEL org.opencontainers.image.vendor="Geekpad"
LABEL org.opencontainers.image.version=${VERSION}

ENV FOUNDRY_HOME="/home/foundry"
ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}

RUN addgroup --system --gid ${FOUNDRY_UID} foundry \
  && adduser --system --uid ${FOUNDRY_UID} --ingroup foundry foundry

RUN apk --update --no-cache add jq su-exec

WORKDIR ${FOUNDRY_HOME}

COPY src/entrypoint.sh src/package.json src/set_password.js src/download_release.js ./
RUN npm install && echo ${VERSION} > image_version.txt

VOLUME ["/data"]

EXPOSE 30000/TCP
ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.js", "--port=30000", "--headless", "--dataPath=/data"]
