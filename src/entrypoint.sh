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

secret_file="/run/secrets/config.json"

# Check for raft secrets
if [ -f "${secret_file}" ]; then
  echo "Reading configured secrets from: ${secret_file}"
  secret_username=$(jq --exit-status --raw-output .foundry_username ${secret_file}) || secret_username=""
  secret_password=$(jq --exit-status --raw-output .foundry_password ${secret_file}) || secret_password=""
  secret_admin_key=$(jq --exit-status --raw-output .foundry_admin_key ${secret_file}) || secret_admin_key=""
  # Override environment variables if secrets were set
  FOUNDRY_USERNAME=${secret_username:-$FOUNDRY_USERNAME}
  FOUNDRY_PASSWORD=${secret_password:-$FOUNDRY_PASSWORD}
  FOUNDRY_ADMIN_KEY=${secret_admin_key:-$FOUNDRY_ADMIN_KEY}
fi

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
  # Determine how we are going to get the release URL
  set +o nounset
  if [ -n "${FOUNDRY_USERNAME}" ] && [ -n "${FOUNDRY_PASSWORD}" ]; then
    echo "Using FOUNDRY_USERNAME and FOUNDRY_PASSWORD to fetch release URL and license."
    if [[ ${CONTAINER_VERBOSE} ]]; then
      s3_url=$(./authenticate.js --log-level=trace --license=license.json "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${FOUNDRY_VERSION}")
    else
      s3_url=$(./authenticate.js --license=license.json "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${FOUNDRY_VERSION}")
    fi
  elif [ -n "${FOUNDRY_RELEASE_URL}" ]; then
    echo "Using FOUNDRY_RELEASE_URL to download release."
    s3_url="${FOUNDRY_RELEASE_URL}"
  else
    echo "Unable to install Foundry: No credentials or release URL provided."
    echo "Either set FOUNDRY_USERNAME and FOUNDRY_PASSWORD."
    echo "Or set FOUNDRY_RELEASE_URL."
    exit 1
  fi

  if [[ ${CONTAINER_CACHE} ]]; then
    echo "Using CONTAINER_CACHE: ${CONTAINER_CACHE}"
    mkdir -p "${CONTAINER_CACHE}"
  fi

  downloading_filename="${CONTAINER_CACHE%%+(/)}${CONTAINER_CACHE:+/}downloading.zip"
  release_filename="${CONTAINER_CACHE%%+(/)}${CONTAINER_CACHE:+/}foundryvtt-${FOUNDRY_VERSION}.zip"

  echo "Downloading Foundry release."
  # Download release if newer than cached version.
  # Filter out warnings about bad date formats if the file is missing.
  curl --fail --time-cond "${release_filename}" \
       --output "${downloading_filename}" "${s3_url}" 2>&1 | \
       tr "\r" "\n" | \
       sed --unbuffered '/^Warning: .* date/d'

  # Rename the download now that it is completed.
  # If we had a cache hit, the file is already renamed.
  mv "${downloading_filename}" "${release_filename}" > /dev/null 2>&1 || true

  echo "Installing Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
  unzip -q "${release_filename}" 'resources/*'

  if [[ ${CONTAINER_CACHE} ]]; then
    echo "Preserving release archive file in cache."
  else
    rm "${release_filename}"
  fi
  set -o nounset

  if [ -f license.json ] && [ ! -f /data/Config/license.json ]; then
    echo "Applying license key."
    mkdir -p /data/Config
    mv license.json /data/Config
  fi

  # apply patches if requested and the directory exists
  if [[ ${CONTAINER_PATCHES} ]]; then
    echo "Using CONTAINER_PATCHES: ${CONTAINER_PATCHES}"
    if [ -d "${CONTAINER_PATCHES}" ]; then
      echo "Container patches directory detected.  Starting patching..."
      for f in "${CONTAINER_PATCHES}"/*
      do
        [ -f "$f" ] || continue # we can't set nullglob in busybox
        echo "Sourcing patch from file: $f"
        # shellcheck disable=SC1090
        source "$f"
      done
      echo "Completed patching."
    else
      echo "Container patches directory not found."
    fi
  fi
fi

if [ "$(id -u)" = 0 ]; then
  # set timezone using environment
  ln -snf /usr/share/zoneinfo/"${TIMEZONE:-UTC}" /etc/localtime

  # ensure the permissions are set correctly
  echo "Setting data directory permissions."
  chown -R "${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}" /data

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
env -i HOME="$HOME" node "$@"
