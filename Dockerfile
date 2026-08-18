# syntax=docker/dockerfile:1

ARG CONTAINER_VERSION
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_VERSION
# Base image coordinates.  DEBIAN_SUITE is the single source of truth: it
# selects the node image variant below and the Debian archives tracked by the
# archive-state stage.  Global ARG defaults are expanded against previously
# declared global ARGs, so the declaration order here matters.
ARG NODE_MAJOR_VERSION=24
ARG DEBIAN_SUITE=trixie
ARG NODE_IMAGE_VERSION=${NODE_MAJOR_VERSION}-${DEBIAN_SUITE}-slim
ARG NPM_VERSION=11.12.1

# This stage exists solely to track the state of the Debian archives that carry
# security fixes.  BuildKit revalidates remote ADD sources on every build and
# derives their cache key from the fetched content, so patched-base below - and
# everything downstream of it - is invalidated exactly when these archives are
# republished.  Without this, the RUN in patched-base would be cached
# indefinitely and would silently stop applying new security updates.
#
# The InRelease files are architecture independent (~45 KB each) and are only
# bind-mounted, so nothing from this stage is committed to any image layer.
FROM scratch AS archive-state
ARG DEBIAN_SUITE
ADD https://deb.debian.org/debian-security/dists/${DEBIAN_SUITE}-security/InRelease /security
ADD https://deb.debian.org/debian/dists/${DEBIAN_SUITE}-updates/InRelease /updates

# Apply Debian security updates for every downstream stage.  The upstream node
# image's Debian rootfs is built from the main archive only, so fixes published
# to <suite>-security are absent from it until a Debian point release folds
# them into main.  This affects the shipped image and the stages that handle
# credentials and untrusted downloads alike.
FROM public.ecr.aws/docker/library/node:${NODE_IMAGE_VERSION} AS patched-base
RUN --mount=type=bind,from=archive-state,target=/run/archive-state \
  apt-get update \
  && apt-get upgrade -y --with-new-pkgs \
  && rm -rf /var/lib/apt/lists/*

FROM patched-base AS base
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
