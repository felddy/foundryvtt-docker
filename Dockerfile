ARG GIT_COMMIT=unspecified
ARG GIT_REMOTE=unspecified
ARG VERSION=unspecified
ARG HOTFIX_VERSION

# Unarchiver Stage
FROM alpine:latest as stage-1
ARG VERSION
ARG HOTFIX_VERSION
ENV ARCHIVE="foundryvtt-${VERSION}.zip"
ENV HOTFIX_ARCHIVE="FoundryVTT-${HOTFIX_VERSION}-Hotfix.zip"

WORKDIR /root
COPY archives ./
RUN mkdir dist
RUN unzip -d dist ${ARCHIVE}
RUN if [ -n "${HOTFIX_VERSION}" ]; then \
      unzip -o -d dist/resources/app ${HOTFIX_ARCHIVE} ; \
    fi

# Final Stage
FROM node:12-alpine as stage-2

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

ARG FOUNDRY_UID=421
ENV FOUNDRY_HOME="/home/foundry"

RUN addgroup --system --gid ${FOUNDRY_UID} foundry \
  && adduser --system --uid ${FOUNDRY_UID} --ingroup foundry foundry

RUN apk --update --no-cache add su-exec

WORKDIR ${FOUNDRY_HOME}

COPY --from=stage-1 /root/dist/ .
COPY src/entrypoint.sh src/set_password.js ./

VOLUME ["/data"]

EXPOSE 30000/TCP
ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.js", "--port=30000", "--headless", "--dataPath=/data"]
