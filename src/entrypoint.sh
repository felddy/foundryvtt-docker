#!/bin/sh

set -o nounset
set -o errexit
# Sha-bang cannot be /bin/bash (not available), but
# the container's /bin/sh does support pipefail.
# shellcheck disable=SC2039
set -o pipefail

if [ "$(id -u)" = 0 ]; then
  # set timezone using environment
  ln -snf /usr/share/zoneinfo/"${TIMEZONE:-UTC}" /etc/localtime
  # drop privileges and restart this script as foundry user
  su-exec "${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}" "$(readlink -f "$0")" "$@"
  exit 0
fi

if [ "$1" = "--shell" ]; then
  /bin/sh
  exit $?
fi

# Update configuration file
# /bin/sh does support >&
# shellcheck disable=SC2039
mkdir -p /data/Config >& /dev/null
cat <<EOF > /data/Config/options.json
{
  "port": 30000,
  "upnp": ${FOUNDRY_UPNP:-false},
  "fullscreen": false,
  "hostname": ${FOUNDRY_HOSTNAME:-null},
  "routePrefix": ${FOUNDRY_ROUTE_PREFIX:-null},
  "sslCert": ${FOUNDRY_SSL_CERT:-null},
  "sslKey": ${FOUNDRY_SSL_KEY:-null},
  "awsConfig": null,
  "dataPath": "/data",
  "proxySSL": ${FOUNDRY_PROXY_SSL:-false},
  "proxyPort": ${FOUNDRY_PROXY_PORT:-null},
  "updateChannel": ${FOUNDRY_UPDATE_CHANNEL:-\"beta\"},
  "world": ${FOUNDRY_WORLD:-null}
}
EOF

# Save admin password if it is set
if [ -n "${FOUNDRY_ADMIN_KEY}" ]; then
  echo "${FOUNDRY_ADMIN_KEY}" | ./set_password.js > /data/Config/admin.txt
else
  # shellcheck disable=SC2039
  rm /data/Config/admin.txt >& /dev/null || true
fi

node "$@"
