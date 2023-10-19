#!/bin/sh
# shellcheck disable=SC3001,SC3010,SC3021,SC3046,SC3051
# SC3001 - busybox supports process substitution
# SC3010 - busybox supports [[ ]]
# SC3021 - busybox supports >&
# SC3046 - busybox supports source command
# SC3051 - busybox supports source command

set -o nounset
set -o errexit
# shellcheck disable=SC3040
# pipefail is supported by busybox
set -o pipefail

CONFIG_DIR="/data/Config"
ADMIN_KEY_FILE="${CONFIG_DIR}/admin.txt"
CONFIG_FILE="${CONFIG_DIR}/options.json"
# shellcheck disable=SC2034
# LOG_NAME used in sourced file
LOG_NAME="Launcher"

# shellcheck source=src/logging.sh
source logging.sh

# ensure the config directory exists
log_debug "Ensuring ${CONFIG_DIR} directory exists."
mkdir -p "${CONFIG_DIR}"

if [[ "${CONTAINER_PRESERVE_CONFIG:-}" == "true" && -f "${CONFIG_FILE}" ]]; then
  log_warn "CONTAINER_PRESERVE_CONFIG is set: Not updating options.json"
else
  # Update configuration file
  log "Generating options.json file."
  ./set_options.js > "${CONFIG_FILE}"
fi

if [[ "${CONTAINER_PRESERVE_CONFIG:-}" == "true" && -f "${ADMIN_KEY_FILE}" ]]; then
  log_warn "CONTAINER_PRESERVE_CONFIG is set: Not updating admin.txt"
else
  # Save admin access key to file if set.  Delete file if unset.
  if [[ "${FOUNDRY_ADMIN_KEY:-}" ]]; then
    log "Setting 'Admin Access Key'."
    echo "${FOUNDRY_ADMIN_KEY}" | ./set_password.js > "${ADMIN_KEY_FILE}"
  else
    log_warn "No 'Admin Access Key' has been configured."
    rm "${ADMIN_KEY_FILE}" >&/dev/null || true
  fi
fi

if [ "$1" = "--shell" ]; then
  log_warn "Starting a shell as requested by argument --shell"
  /bin/sh
  exit $?
fi

if [[ "${FOUNDRY_IP_DISCOVERY:-}" == "false" ]]; then
  log "FOUNDRY_IP_DISCOVERY is set to false: Disabling IP discovery."
  # Add argument to disable IP discovery
  set -- "$@" --noipdiscovery
fi

# Space seperated list of regex rules which environment variables must meet to
# be carried over to the new environment, which Node/Foundry will be running in.
ENV_VAR_PASSLIST_REGEX='^HOME$ ^NODE_.+$'
# Build list of environment variables to carry over into a clean environment
ENV_VAR_CARRY_LIST=''
# shellcheck disable=SC3045
# busybox read supports the -rd option
while IFS='=' read -rd '' ENV_VAR_NAME ENV_VAR_VALUE; do
  for VAR_REGEX in $ENV_VAR_PASSLIST_REGEX; do
    if [[ $ENV_VAR_NAME =~ ${VAR_REGEX} ]]; then
      ENV_VAR_CARRY_LIST="${ENV_VAR_CARRY_LIST} ${ENV_VAR_NAME}=${ENV_VAR_VALUE}"
      break
    fi
  done
done < <(env -0)

# Exec node with clean environment to prevent credential leaks
log "Starting Foundry Virtual Tabletop."
# We want ENV_VAR_CARRY_LIST to word split
# shellcheck disable=SC2086
exec env -i $ENV_VAR_CARRY_LIST node "$@" || log_error "Exec failed with code $?"
