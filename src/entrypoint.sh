#!/bin/sh
# shellcheck disable=SC2039
# busybox supports more features than POSIX /bin/sh

set -o nounset
set -o errexit
set -o pipefail

CONFIG_DIR="/data/Config"
LANGUAGE_FILE="$FOUNDRY_HOME/resources/app/public/lang/en.json"
LICENSE_FILE="${CONFIG_DIR}/license.json"
# setup logging
# shellcheck disable=SC2034
# LOG_NAME used in sourced file
LOG_NAME="Entrypoint"
UPDATE_WARNING="This instance of Foundry Virtual Tabletop is running in a Docker container.  To update, please pull a new Docker image and restart the container."
# shellcheck disable=SC1091
# disable following
source logging.sh

image_version=$(cat image_version.txt)

if [ "$1" = "--version" ]; then
  echo "${image_version}"
  exit 0
fi

# Set the timezone before we start logging dates
if [ "$(id -u)" = 0 ]; then
  # set timezone using environment
  ln -snf /usr/share/zoneinfo/"${TIMEZONE:-UTC}" /etc/localtime
  log_debug "Timezone set to: ${TIMEZONE:-UTC}"
fi

log "Starting felddy/foundryvtt container v${image_version}"
log_debug "CONTAINER_VERBOSE set.  Debug logging enabled."

cookiejar_file="cookiejar.json"
license_min_length=24
secret_file="/run/secrets/config.json"

# Check for raft secrets
if [ -f "${secret_file}" ]; then
  log "Reading configured secrets from: ${secret_file}"
  secret_admin_key=$(jq --exit-status --raw-output .foundry_admin_key ${secret_file}) || secret_admin_key=""
  secret_license_key=$(jq --exit-status --raw-output .foundry_license_key ${secret_file}) || secret_license_key=""
  secret_password=$(jq --exit-status --raw-output .foundry_password ${secret_file}) || secret_password=""
  secret_username=$(jq --exit-status --raw-output .foundry_username ${secret_file}) || secret_username=""
  # Override environment variables if secrets were set
  FOUNDRY_ADMIN_KEY=${secret_admin_key:-${FOUNDRY_ADMIN_KEY:-}}
  FOUNDRY_LICENSE_KEY=${secret_license_key:-${FOUNDRY_LICENSE_KEY:-}}
  FOUNDRY_PASSWORD=${secret_password:-${FOUNDRY_PASSWORD:-}}
  FOUNDRY_USERNAME=${secret_username:-${FOUNDRY_USERNAME:-}}
fi

# Check to see if an install is required
install_required=false
if [ -f "resources/app/package.json" ]; then
  installed_version=$(jq --raw-output .version resources/app/package.json)
  log "Foundry Virtual Tabletop ${installed_version} is installed."
  if [ "${FOUNDRY_VERSION}" != "${installed_version}" ]; then
    log "Requested version (${FOUNDRY_VERSION}) from FOUNDRY_VERSION differs."
    log "Uninstalling version ${installed_version}."
    rm -r resources
    install_required=true
  fi
else
  log "No Foundry Virtual Tabletop installation detected."
  install_required=true
fi

# Install FoundryVTT if needed
if [ $install_required = true ]; then
  # Determine how we are going to get the release URL
  if [ "${FOUNDRY_RELEASE_URL:-}" ]; then
    log "Using FOUNDRY_RELEASE_URL to download release."
    s3_url="${FOUNDRY_RELEASE_URL}"
  fi
  if [[ "${FOUNDRY_USERNAME:-}" && "${FOUNDRY_PASSWORD:-}" ]]; then
    log "Using FOUNDRY_USERNAME and FOUNDRY_PASSWORD to authenticate."
    # If credentials are provided attempt authentication.
    # The resulting cookiejar is used to get a release URL or license.
    # CONTAINER_VERBOSE default value should not be quoted.
    # shellcheck disable=SC2086
    ./authenticate.js ${CONTAINER_VERBOSE+--log-level=debug} "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${cookiejar_file}"
    if [[ ! "${s3_url:-}" ]]; then
      # If the s3_url wasn't set by FOUNDRY_RELEASE_URL generate one now.
      log "Using authenticated credentials to download release."
      # CONTAINER_VERBOSE default value should not be quoted.
      # shellcheck disable=SC2086
      s3_url=$(./get_release_url.js ${CONTAINER_VERBOSE+--log-level=debug} "${cookiejar_file}" "${FOUNDRY_VERSION}")
    fi
  fi

  if [[ "${CONTAINER_CACHE:-}" ]]; then
    log "Using CONTAINER_CACHE: ${CONTAINER_CACHE}"
    mkdir -p "${CONTAINER_CACHE}"
  fi

  set +o nounset
  downloading_filename="${CONTAINER_CACHE%%+(/)}${CONTAINER_CACHE:+/}downloading.zip"
  release_filename="${CONTAINER_CACHE%%+(/)}${CONTAINER_CACHE:+/}foundryvtt-${FOUNDRY_VERSION}.zip"
  set -o nounset

  if [[ "${s3_url:-}" ]]; then
    log "Downloading Foundry Virtual Tabletop release."
    # Download release if newer than cached version.
    # Filter out warnings about bad date formats if the file is missing.
    curl --fail --location --time-cond "${release_filename}" \
         --output "${downloading_filename}" "${s3_url}" 2>&1 | \
         tr "\r" "\n" | \
         sed --unbuffered '/^Warning: .* date/d'

    # Rename the download now that it is completed.
    # If we had a cache hit, the file is already renamed.
    mv "${downloading_filename}" "${release_filename}" > /dev/null 2>&1 || true
  fi

  if [ -f "${release_filename}" ]; then
    log "Installing Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
    unzip -q "${release_filename}" 'resources/*'
    log_debug "Installation completed."
  else
    log_error "Unable to install Foundry Virtual Tabletop!"
    log_error "Either set set FOUNDRY_RELEASE_URL."
    log_error "Or set FOUNDRY_USERNAME and FOUNDRY_PASSWORD."
    log_error "Or set CONTAINER_CACHE to a directory containing foundryvtt-${FOUNDRY_VERSION}.zip"
    exit 1
  fi

  if [[ "${CONTAINER_CACHE:-}" ]]; then
    log "Preserving release archive file in cache."
  else
    log "Deleting release archive file."
    rm "${release_filename}"
  fi

  # apply URL patches if requested
  if [[ "${CONTAINER_PATCH_URLS:-}" ]]; then
    log_warn "CONTAINER_PATCH_URLS is set:  Only use patch URLs from trusted sources!"
      for url in ${CONTAINER_PATCH_URLS}
      do
        log "Downloading patch from URL: $url"
        patch_file=$(mktemp -t patch_url.sh.XXXXXX)
        curl --silent --output "${patch_file}" "${url}"
        log_debug "Sourcing patch file: ${patch_file}"
        # shellcheck disable=SC1090
        source "${patch_file}"
      done
      log "Completed URL patching."
  fi

  # apply patches if requested and the directory exists
  if [[ "${CONTAINER_PATCHES:-}" ]]; then
    log "Using CONTAINER_PATCHES: ${CONTAINER_PATCHES}"
    if [ -d "${CONTAINER_PATCHES}" ]; then
      log "Container patches directory detected.  Starting patch application..."
      for f in "${CONTAINER_PATCHES}"/*
      do
        [ -f "$f" ] || continue # we can't set nullglob in busybox
        log "Sourcing patch from file: $f"
        # shellcheck disable=SC1090
        source "$f"
      done
      log "Completed file patching."
    else
      log_warn "Container patches directory not found."
    fi
  fi

  # Modify update warnings to be container-specific.
  log_debug "Editing server update error message."
  patch_lang_file=$(mktemp -t patch_lang.XXXXXX)
  jq --arg msg "${UPDATE_WARNING}" --exit-status \
  '."SETUP.UpdateWarning" = $msg | ."SETUP.UpdateNoUpdate" = $msg' \
  "${LANGUAGE_FILE}" > "${patch_lang_file}"
  mv "${patch_lang_file}" "${LANGUAGE_FILE}"
fi  # install required

if [ ! -f "${LICENSE_FILE}" ]; then
  log "Installation not yet licensed."
  log_debug "Ensuring ${CONFIG_DIR} directory exists."
  mkdir -p "${CONFIG_DIR}"
  set +o nounset # length check will fail
  if [[ ${#FOUNDRY_LICENSE_KEY} -ge ${license_min_length} ]]; then
    set -o nounset
    log "Applying license key passed via FOUNDRY_LICENSE_KEY."
    # FOUNDRY_LICENSE_KEY is long enough to be a key
    echo "{ \"license\": \"${FOUNDRY_LICENSE_KEY}\" }" | tr -d '-' > "${LICENSE_FILE}"
  elif [ -f ${cookiejar_file} ]; then
    log "Attempting to fetch license key from authenticated account."
    if [[ "${FOUNDRY_LICENSE_KEY:-}" ]]; then
      # FOUNDRY_LICENSE_KEY can be an index, try passing it.
      # CONTAINER_VERBOSE default value should not be quoted.
      # shellcheck disable=SC2086
      fetched_license_key=$(./get_license.js ${CONTAINER_VERBOSE+--log-level=debug} --select="${FOUNDRY_LICENSE_KEY}" "${cookiejar_file}")
    else
      # shellcheck disable=SC2086
      fetched_license_key=$(./get_license.js ${CONTAINER_VERBOSE+--log-level=debug} "${cookiejar_file}")
    fi
    echo "{ \"license\": \"${fetched_license_key}\" }" > "${LICENSE_FILE}"
  else
    log_warn "Unable to apply a license key since neither a license key nor credentials were provided.  The license key will need to be entered in the browser."
  fi
  set -o nounset
else
  log "Not modifying existing installation license key."
fi

# ensure the permissions are set correctly
log "Setting data directory permissions."
find /data -regex "${CONTAINER_PRESERVE_OWNER:-}" -prune -o -exec chown "${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}" {} +
log_debug "Completed setting directory permissions."

if [ "$1" = "--root-shell" ]; then
  log_warn "Starting a shell as requested by argument --root-shell"
  /bin/sh
  exit $?
fi

# drop privileges and handoff to launcher
log "Starting launcher with uid:gid as ${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}."
export CONTAINER_PRESERVE_CONFIG FOUNDRY_ADMIN_KEY FOUNDRY_AWS_CONFIG \
  FOUNDRY_HOSTNAME FOUNDRY_LANGUAGE FOUNDRY_LOCAL_HOSTNAME \
  FOUNDRY_MINIFY_STATIC_FILES FOUNDRY_PROXY_PORT FOUNDRY_PROXY_SSL \
  FOUNDRY_ROUTE_PREFIX FOUNDRY_SSL_CERT FOUNDRY_SSL_KEY FOUNDRY_TURN_CONFIGS \
  FOUNDRY_TURN_MAX_PORT FOUNDRY_UPNP FOUNDRY_UPNP_LEASE_DURATION FOUNDRY_WORLD
su-exec "${FOUNDRY_UID:-foundry}:${FOUNDRY_GID:-foundry}" ./launcher.sh "$@"
exit 0
