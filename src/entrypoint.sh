#!/bin/sh
# shellcheck disable=SC2039
# busybox supports more features that POSIX /bin/sh

set -o nounset
set -o errexit
set -o pipefail


image_version=$(cat image_version.txt)

if [ "$1" = "--version" ]; then
  echo "${image_version}"
  exit 0
fi

echo "Starting felddy/foundryvtt container v${image_version}"

# Check to see if an install is required
install_required=false
if [ -f "resources/app/package.json" ]; then
  installed_version=$(jq --raw-output .version resources/app/package.json)
  echo "Foundry Virtual Tabletop ${installed_version} is installed."
  if [ "${FOUNDRY_VERSION}" != "${installed_version}" ]; then
    echo "Requested version (${FOUNDRY_VERSION}) from FOUNDRY_VERSION differs."
    echo "Uninstalling version ${FOUNDRY_VERSION}."
    rm -r resources
    install_required=true
  fi
else
  echo "No Foundry Virtual Tabletop installation detected."
  install_required=true
fi

# Install FoundryVTT if needed
if [ $install_required = true ]; then
  set +o nounset
  if [ -z "${FOUNDRY_USERNAME}" ] || [ -z "${FOUNDRY_PASSWORD}" ]; then
    echo "FOUNDRY_USERNAME and FOUNDRY_PASSWORD must be set to install FoundryVTT."
    exit 1
  fi
  echo "Installing Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
  if [[ ${CONTAINER_VERBOSE} ]]; then
    ./download_release.js --log-level=trace "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${FOUNDRY_VERSION}"
  else
    ./download_release.js "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${FOUNDRY_VERSION}"
  fi
  set -o nounset
  unzip -q "foundryvtt-${FOUNDRY_VERSION}.zip" 'resources/*'
  rm "foundryvtt-${FOUNDRY_VERSION}.zip"
  if [ -f license.json ] && [ ! -f /data/Config/license.json ]; then
    mkdir -p /data/Config
    mv license.json /data/Config
    chown -R "${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}" /data
  fi
fi

if [ "$(id -u)" = 0 ]; then
  # set timezone using environment
  ln -snf /usr/share/zoneinfo/"${TIMEZONE:-UTC}" /etc/localtime
  if [ "${FOUNDRY_UID:-foundry}" != 0 ]; then
    # drop privileges and restart this script as foundry user
    echo "Switching uid:gid to ${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry} and restarting."
    su-exec "${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}" "$(readlink -f "$0")" "$@"
    exit 0
  fi
fi

if [ "$1" = "--shell" ]; then
  /bin/sh
  exit $?
fi

# Quote all strings for insertion into json
# busybox does not implement ${VAR@Q} substitution to quote variables

set +o nounset
if [[ $FOUNDRY_AWS_CONFIG ]]; then
  if [[ $FOUNDRY_AWS_CONFIG == "true" ]];then
    FOUNDRY_AWS_CONFIG=true
  else
    FOUNDRY_AWS_CONFIG=\"${FOUNDRY_AWS_CONFIG}\"
  fi
fi
if [[ $FOUNDRY_HOSTNAME ]]; then
  FOUNDRY_HOSTNAME=\"${FOUNDRY_HOSTNAME}\"
fi
if [[ $FOUNDRY_ROUTE_PREFIX ]]; then
  FOUNDRY_ROUTE_PREFIX=\"${FOUNDRY_ROUTE_PREFIX}\"
fi
if [[ $FOUNDRY_SSL_CERT ]]; then
  FOUNDRY_SSL_CERT=\"${FOUNDRY_SSL_CERT}\"
fi
if [[ $FOUNDRY_SSL_KEY ]]; then
  FOUNDRY_SSL_KEY=\"${FOUNDRY_SSL_KEY}\"
fi
if [[ $FOUNDRY_UPDATE_CHANNEL ]]; then
  FOUNDRY_UPDATE_CHANNEL=\"${FOUNDRY_UPDATE_CHANNEL}\"
fi
if [[ $FOUNDRY_WORLD ]]; then
  FOUNDRY_WORLD=\"${FOUNDRY_WORLD}\"
fi
set -o nounset

# Update configuration file
mkdir -p /data/Config >& /dev/null
echo "Generating options.json file."
cat <<EOF > /data/Config/options.json
{
  "awsConfig": ${FOUNDRY_AWS_CONFIG:-null},
  "dataPath": "/data",
  "fullscreen": false,
  "hostname": ${FOUNDRY_HOSTNAME:-null},
  "noUpdate": ${FOUNDRY_NO_UPDATE:-true},
  "port": 30000,
  "proxyPort": ${FOUNDRY_PROXY_PORT:-null},
  "proxySSL": ${FOUNDRY_PROXY_SSL:-false},
  "routePrefix": ${FOUNDRY_ROUTE_PREFIX:-null},
  "sslCert": ${FOUNDRY_SSL_CERT:-null},
  "sslKey": ${FOUNDRY_SSL_KEY:-null},
  "updateChannel": ${FOUNDRY_UPDATE_CHANNEL:-\"release\"},
  "upnp": ${FOUNDRY_UPNP:-false},
  "world": ${FOUNDRY_WORLD:-null}
}
EOF

# Save Admin Access Key if it is set
set +o nounset
if [ -n "${FOUNDRY_ADMIN_KEY}" ]; then
  echo "Setting 'Admin Access Key'."
  echo "${FOUNDRY_ADMIN_KEY}" | ./set_password.js > /data/Config/admin.txt
else
  echo "Warning: No 'Admin Access Key' has been configured."
  rm /data/Config/admin.txt >& /dev/null || true
fi
set -o nounset

# Spawn node with clean environment to prevent credential leaks
echo "Starting Foundry Virtual Tabletop."
env -i node "$@"
