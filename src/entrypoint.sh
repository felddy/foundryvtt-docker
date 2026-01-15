#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

DATA_DIR="/data"
CONFIG_DIR="${DATA_DIR}/Config"
DEPRECATED_ENVS="CONTAINER_PRESERVE_OWNER FOUNDRY_UID FOUNDRY_GID TIMEZONE"
LICENSE_FILE="${CONFIG_DIR}/license.json"
# setup logging
# shellcheck disable=SC2034
# LOG_NAME used in sourced file
LOG_NAME="Entrypoint"

# shellcheck source=src/logging.sh
source logging.sh

image_version=$(cat image_version.txt)

if [ "$1" = "--version" ]; then
  echo "${image_version}"
  exit 0
fi

# Warn about deprecated environment variables
for deprecated_env in $DEPRECATED_ENVS; do
  if [ -n "${!deprecated_env:-}" ]; then
    log_warn "The environment variable \"$deprecated_env\" is deprecated and will be ignored."
  fi
done

# Setup the SIGTERM handler
# shellcheck disable=SC2329
# SC2329 - shellcheck does not understand reachability via traps
handle_sigterm() {
  log_warn "TERM signal received.  Shutting down server."
  # Only attempt to terminate if the child process is still running
  if kill -0 "$child_pid" 2> /dev/null; then
    log_debug "Sending TERM signal to child pid: ${child_pid}"
    kill -TERM "$child_pid" 2> /dev/null
  else
    log_warn "Child pid: ${child_pid} exited before we could sent TERM signal."
  fi
}

log "Starting felddy/foundryvtt container v${image_version}"
log_debug "CONTAINER_VERBOSE set.  Debug logging enabled."
log_debug "Running as: $(id)"
log_debug "Environment:\n$(env | sort | sed -E 's/(.*PASSWORD|KEY.*)=.*/\1=[REDACTED]/g')"
log_debug "Data directory: ${DATA_DIR}"

# Show the mount details for the data directory
mount_info=$(findmnt -n -o SOURCE,FSTYPE,OPTIONS --target "${DATA_DIR}")
log_debug "Mount info for ${DATA_DIR}: ${mount_info}"

# Test volume permissions
permissions_test_file="${DATA_DIR}/.container-permissions-test.txt"
permission_test_failed=0
log_debug "Testing permissions on ${permissions_test_file}"
if ! touch "${permissions_test_file}" 2> /dev/null; then
  log_error "Volume write test failed."
  permission_test_failed=1
else
  log_debug "Volume write test succeeded."
fi
if ! cat "${permissions_test_file}" > /dev/null 2>&1; then
  log_error "Volume read test failed."
  permission_test_failed=1
else
  log_debug "Volume read test succeeded."
fi
if ! rm -f "${permissions_test_file}" 2> /dev/null; then
  log_error "Volume delete test failed."
  permission_test_failed=1
else
  log_debug "Volume delete test succeeded."
fi
if [ "${permission_test_failed}" -ne 0 ]; then
  log_error "Aborting due to insufficient permissions on ${DATA_DIR}"
  log_error "Container running as uid:gid: $(id -u):$(id -g)"
  log_error "For more information see the discussion at: https://github.com/felddy/foundryvtt-docker/discussions/1197"
  exit 1
fi
log_debug "All permissions tests succeeded."

cookiejar_file="/tmp/cookiejar.json"
license_min_length=24
secret_file="/run/secrets/config.json"

# Calculate a user-agent comment to use in for curl and node-fetch requests
CONTAINER_USER_AGENT_COMMENT="(felddy/foundryvtt:${image_version})"
curl_user_agent=$(curl --version | awk 'NR==1 {print $1 "/" $2}')" ${CONTAINER_USER_AGENT_COMMENT}"
node_user_agent="node-fetch ${CONTAINER_USER_AGENT_COMMENT}"

# Warn user if the container version does not start with the FOUNDRY_VERSION.
# The FOUNDRY_VERSION looks like x.yyy
# The container version is a semver x.y.z
if [[ ${image_version%.*} != "${FOUNDRY_VERSION}" ]]; then
  log_warn "FOUNDRY_VERSION has been manually set and does not match the container's version."
  log_warn "Expected ${image_version%.*} but found ${FOUNDRY_VERSION}"
  log_warn "The container may not function properly with this version mismatch."
fi

# Check for raft secrets
if [ -f "${secret_file}" ]; then
  log "Reading configured secrets from: ${secret_file}"
  secret_admin_key=$(jq --exit-status --raw-output .foundry_admin_key ${secret_file}) || secret_admin_key=""
  secret_license_key=$(jq --exit-status --raw-output .foundry_license_key ${secret_file}) || secret_license_key=""
  secret_password=$(jq --exit-status --raw-output .foundry_password ${secret_file}) || secret_password=""
  secret_password_salt=$(jq --exit-status --raw-output .foundry_password_salt ${secret_file}) || secret_password_salt=""
  secret_username=$(jq --exit-status --raw-output .foundry_username ${secret_file}) || secret_username=""
  # Override environment variables if secrets were set
  FOUNDRY_ADMIN_KEY=${secret_admin_key:-${FOUNDRY_ADMIN_KEY:-}}
  FOUNDRY_LICENSE_KEY=${secret_license_key:-${FOUNDRY_LICENSE_KEY:-}}
  FOUNDRY_PASSWORD=${secret_password:-${FOUNDRY_PASSWORD:-}}
  FOUNDRY_PASSWORD_SALT=${secret_password_salt:-${FOUNDRY_PASSWORD_SALT:-}}
  FOUNDRY_USERNAME=${secret_username:-${FOUNDRY_USERNAME:-}}
fi

# Check to see if an install is required
install_required=false
# Track whether a presigned URL request is made.
# We use this information to protect from a download loop.
requested_presigned_url=false
if [ -f "resources/app/package.json" ]; then
  # FoundryVTT no longer supports the "version" field in package.json
  # We need to build up a pseudo-version using the generation and build values
  installed_version=$(jq --raw-output '.release | "\(.generation).\(.build)"' resources/app/package.json)
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
    presigned_url="${FOUNDRY_RELEASE_URL}"
  fi
  if [[ "${FOUNDRY_USERNAME:-}" && "${FOUNDRY_PASSWORD:-}" ]]; then
    log "Using FOUNDRY_USERNAME and FOUNDRY_PASSWORD to authenticate."
    # If credentials are provided attempt authentication.
    # The resulting cookiejar is used to get a release URL or license.

    # Temporarily disable errexit to capture failure from authenticate.js
    set +e
    ./authenticate.js ${CONTAINER_VERBOSE+--log-level=debug} \
      --user-agent="${node_user_agent}" \
      "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${cookiejar_file}"
    auth_exit_code=$?
    set -e

    if [ ${auth_exit_code} -ne 0 ]; then
      log_warn "Authentication failed with exit code ${auth_exit_code}."
      rm -f "${cookiejar_file}"
    elif [[ ! "${presigned_url:-}" ]]; then
      # If the presigned_url wasn't set by FOUNDRY_RELEASE_URL generate one now.
      log "Using authenticated credentials to fetch release URL."
      presigned_url=$(./get_release_url.js ${CONTAINER_VERBOSE+--log-level=debug} \
        ${CONTAINER_URL_FETCH_RETRY+--retry=${CONTAINER_URL_FETCH_RETRY}} \
        --user-agent="${node_user_agent}" \
        "${cookiejar_file}" "${FOUNDRY_VERSION}")
      requested_presigned_url=true
    fi
  fi

  # If CONTAINER_CACHE is null, set it to a default.
  # If it set to an empty string, disable the caching.
  CONTAINER_CACHE="${CONTAINER_CACHE-${DATA_DIR}/container_cache}"

  if [[ "${CONTAINER_CACHE:-}" ]]; then
    log "Using CONTAINER_CACHE: ${CONTAINER_CACHE}"
    mkdir -p "${CONTAINER_CACHE}"
    # Create a cache marker file in the cache directory.
    cat << END_OF_LINE > "${CONTAINER_CACHE}/CACHEDIR.TAG"
Signature: $(printf ".IsCacheDirectory" | md5sum | cut -d ' ' -f 1)
# This file is a cache directory tag created by the felddy/foundryvtt container
# https://github.com/felddy/foundryvtt-docker
# For information about cache directory tags see https://bford.info/cachedir/
END_OF_LINE
  else
    log_warn "CONTAINER_CACHE has been unset.  Release caching is disabled."
  fi

  set +o nounset
  downloading_filename="${CONTAINER_CACHE%%+(/)}${CONTAINER_CACHE:+/}downloading.zip"
  release_filename="${CONTAINER_CACHE%%+(/)}${CONTAINER_CACHE:+/}foundryvtt-${FOUNDRY_VERSION}.zip"
  set -o nounset

  if [[ "${presigned_url:-}" ]]; then
    log "Downloading Foundry Virtual Tabletop release."
    # Temporarily disable errexit for the curl command to capture its exit status
    set +e
    # Download release if newer than cached version.
    # Filter out warnings about bad date formats if the file is missing.
    curl ${CONTAINER_VERBOSE+--verbose} --fail --location \
      --user-agent "${curl_user_agent}" \
      --time-cond "${release_filename}" \
      --output "${downloading_filename}" "${presigned_url}" 2>&1 \
      | tr "\r" "\n" \
      | sed --unbuffered '/^Warning: .* date/d'
    curl_exit_code=$?
    set -e

    if [ ${curl_exit_code} -ne 0 ]; then
      log_warn "Download from presigned URL failed with exit code ${curl_exit_code}."
      # Remove any partially downloaded file
      [ -f "${downloading_filename}" ] && rm -f "${downloading_filename}"

      if [ -f "${release_filename}" ]; then
        log "Falling back to existing cached release file: ${release_filename}"
      else
        log_error "No valid cached release file found. Unable to proceed with installation."
        exit 1
      fi
    else
      # Download succeeded so rename the file to the final name.
      # If we had a cache hit, the file is already renamed.
      mv "${downloading_filename}" "${release_filename}" > /dev/null 2>&1 || true
    fi
  fi

  if [ -f "${release_filename}" ]; then
    log "Installing Foundry Virtual Tabletop ${FOUNDRY_VERSION}"

    # Check the mime-type of the file
    log_debug "Checking mime-type of release file: ${release_filename}"
    mime_type=$(file --mime-type --brief "${release_filename}")
    log_debug "Found mime-type: ${mime_type}"

    # Check if the file is a zip archive
    if [ "${mime_type}" = "application/zip" ]; then
      if grep -q "^resources/app/main.mjs" <(zipinfo -1 "${release_filename}"); then
        log_debug "Extracting Linux release file."
        log_warn "You can conserve disk space by using Node.js releases instead of Linux releases."
        unzip -q "${release_filename}" 'resources/*'
      else
        log_debug "Extracting Node.js release file."
        mkdir -p "resources/app"
        unzip -q "${release_filename}" -d "resources/app"
      fi
      log_debug "Installation completed."
    else # The user provided the wrong file.
      if [ "${mime_type}" = "application/vnd.microsoft.portable-executable" ]; then
        log_error "The release file appears to be a Windows executable (.exe)."
      elif [ "${mime_type}" = "application/zlib" ]; then
        log_error "The release file appears to be a Mac disk image (.dmg)."
      else
        log_error "The release file does not contain the expected zip data."
        log_error "Found: ${mime_type} instead of application/zip"
      fi
      log_error "Please provide the 'Linux/NodeJS' version of the release or URL."
      log_warn "Deleting invalid release file from cache."
      rm "${release_filename}"
      exit 1
    fi # mime_type is zip
  else # release_filename does not exist
    log_error "Unable to install Foundry Virtual Tabletop!"
    log_error "Either set FOUNDRY_RELEASE_URL."
    log_error "Or set FOUNDRY_USERNAME and FOUNDRY_PASSWORD."
    log_error "Or set CONTAINER_CACHE to a directory containing foundryvtt-${FOUNDRY_VERSION}.zip"
    exit 1
  fi

  if [[ "${CONTAINER_CACHE:-}" ]]; then
    log "Preserving release archive file in cache."
    # Check if CONTAINER_CACHE_SIZE is set and if so, ensure it's greater than 0
    if [[ -n "${CONTAINER_CACHE_SIZE:-}" ]]; then
      if ! [[ "${CONTAINER_CACHE_SIZE}" -gt 0 ]] 2> /dev/null; then
        log_error "If set, CONTAINER_CACHE_SIZE must be 1 or greater.  Found: ${CONTAINER_CACHE_SIZE}"
        exit 1
      fi

      log "Cleaning up cache directory: ${CONTAINER_CACHE}"
      log "Keeping ${CONTAINER_CACHE_SIZE} latest versions."
      # Initialize counter
      cache_files_removed_count=0

      # Store the list of cache files to remove
      file_list=$(find "${CONTAINER_CACHE}" -maxdepth 1 -name 'foundryvtt-*.zip' \
        | sort -Vr \
        | awk -v keep="${CONTAINER_CACHE_SIZE}" 'NR > keep')

      # Iterate over the file list
      if [ -n "$file_list" ]; then
        for file in $file_list; do
          log_warn "Removing: $file"
          rm -f "$file"
          cache_files_removed_count=$((cache_files_removed_count + 1))
        done
        log "Completed cache cleanup. Removed ${cache_files_removed_count} files."
      else
        log "No cache cleanup was necessary."
      fi
    else
      log_debug "CONTAINER_CACHE_SIZE is not set. Skipping cache cleanup."
    fi
  else
    log "Deleting release archive file."
    rm "${release_filename}"
  fi

  # apply URL patches if requested
  if [[ "${CONTAINER_PATCH_URLS:-}" ]]; then
    log_warn "CONTAINER_PATCH_URLS is set:  Only use patch URLs from trusted sources!"
    for url in ${CONTAINER_PATCH_URLS}; do
      log "Downloading patch from URL: $url"
      patch_file=$(mktemp -t patch_url.sh.XXXXXX)
      curl ${CONTAINER_VERBOSE+--verbose} --silent --location \
        --user-agent "${curl_user_agent}" \
        --output "${patch_file}" "${url}"
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
      shopt -s nullglob # if the directory is empty we want an empty array
      patch_files=("${CONTAINER_PATCHES}"/*)
      shopt -u nullglob
      for f in "${patch_files[@]}"; do
        [ -f "$f" ] || continue # skip non-files
        log "Sourcing patch from file: $f"
        # shellcheck disable=SC1090
        source "$f"
      done
      log "Completed file patching."
    else
      log_warn "Container patches directory not found."
    fi
  fi

  # Modify update and config warnings to be container-specific.
  log_debug "Patching GUI update and configuration messages."
  ./patch_lang.js
fi # install required

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
      fetched_license_key=$(./get_license.js ${CONTAINER_VERBOSE+--log-level=debug} \
        --user-agent="${node_user_agent}" \
        --select="${FOUNDRY_LICENSE_KEY}" \
        "${cookiejar_file}")
    else
      # shellcheck disable=SC2086
      fetched_license_key=$(./get_license.js ${CONTAINER_VERBOSE+--log-level=debug} \
        --user-agent="${node_user_agent}" \
        "${cookiejar_file}")
    fi
    echo "{ \"license\": \"${fetched_license_key}\" }" > "${LICENSE_FILE}"
  else
    log_warn "Unable to apply a license key since neither a license key nor credentials were provided.  The license key will need to be entered in the browser."
  fi
  set -o nounset
else
  log "Not modifying existing installation license key."
fi

# Export variables that were possibly set from secrets
# and are used by the launcher.
export FOUNDRY_ADMIN_KEY FOUNDRY_PASSWORD_SALT

log "Starting launcher."
# set the TERM signal handler
trap handle_sigterm TERM
./launcher.sh "$@" &
child_pid=$!
log_debug "Waiting for child pid: ${child_pid} to exit."
wait "$child_pid"
exit_code=$?
# clear the TERM signal handler
trap - TERM
log_debug "Child process exited with code: ${exit_code}."

# Check if the child exited with an error code
if [ $exit_code -ne 0 ]; then
  log_error "Child process failed with error code: $exit_code"
fi

# If the container requested a new presigned URL but disabled the cache
# we are going to sleep forever to prevent a download loop.
if [[ "${requested_presigned_url}" == "true" && "${CONTAINER_CACHE:-}" == "" ]]; then
  log_warn "Server exited after downloading a release while the CONTAINER_CACHE was disabled."
  log_warn "This configuration could lead to a restart loop putting excessive load on the release server."
  log_warn "Please re-enable the CONTAINER_CACHE to allow the container to safely exit."
  log_warn "Sleeping..."
  while true; do sleep 4; done
fi

exit 0
