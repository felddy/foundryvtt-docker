ARG CONTAINER_VERSION=13.346.0
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_VERSION=13.346
ARG NODE_IMAGE_VERSION=22-bookworm-slim

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

# This stage is optional and will only be executed if the FOUNDRY_RELEASE_URL or
# FOUNDRY_USERNAME and FOUNDRY_PASSWORD secrets are provided.  It will download
# and extract the Foundry VTT release for inclusion in the final stage.

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

RUN \
  --mount=type=secret,id=foundry_username,required=false \
  --mount=type=secret,id=foundry_password,required=false \
  npm install && \
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

FROM node:${NODE_IMAGE_VERSION} AS final-stage

ARG CONTAINER_VERSION
ARG FOUNDRY_VERSION
ARG TARGETPLATFORM
ENV USERNAME="node"
ENV HOME=/home/${USERNAME}
ENV FOUNDRY_VTT_DATA_PATH=/data
ENV MODULE_DIR=${FOUNDRY_VTT_DATA_PATH}/Data/modules/
LABEL com.foundryvtt.version=${FOUNDRY_VERSION}
LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.vendor="Geekpad"

ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}

RUN apt-get update && apt-get install -y \
curl \
file \
jq \
patch \
sed \
tzdata \
unzip \
curl \
file \
jq \
patch \
sed \
tzdata \
unzip

RUN mkdir -p ${HOME}
WORKDIR $HOME
RUN mkdir -p resources ${MODULE_DIR}
VOLUME ["${FOUNDRY_VTT_DATA_PATH}"]

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

RUN rm -rf /var/lib/apt/lists/* \
  && npm install && echo ${CONTAINER_VERSION} > ${HOME}/image_version.txt
RUN chown -R ${USERNAME} ${HOME}
RUN chown -R ${USERNAME} ${FOUNDRY_VTT_DATA_PATH}
USER ${USERNAME}

# HTTP Server
EXPOSE 30000/TCP
# TURN Server
# Not exposing TURN ports due to bug in Docker.
# See: https://github.com/moby/moby/issues/11185
# EXPOSE 33478/UDP
# EXPOSE 49152-65535/UDP




ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.mjs", "--port=30000", "--headless", "--noupdate","--dataPath=/data"]
HEALTHCHECK --start-period=3m --interval=30s --timeout=5s CMD ./check_health.sh
