#!/bin/bash

set -o nounset
set -o errexit
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

if [[ "${CONTAINER_UMASK:-}" ]]; then
  log "CONTAINER_UMASK is set: Setting umask to ${CONTAINER_UMASK}"
  umask "${CONTAINER_UMASK}" || log_warn "Failed to set umask."
fi

if [[ "${FOUNDRY_IP_DISCOVERY:-}" == "false" ]]; then
  log "FOUNDRY_IP_DISCOVERY is set to false: Disabling IP discovery."
  # Add argument to disable IP discovery
  set -- "$@" --noipdiscovery
fi

if [[ "${FOUNDRY_LOG_SIZE:-}" ]]; then
  log "FOUNDRY_LOG_SIZE is set: Setting maximum log size to ${FOUNDRY_LOG_SIZE}."
  set -- "$@" --logsize="${FOUNDRY_LOG_SIZE}"
fi

if [[ "${FOUNDRY_MAX_LOGS:-}" ]]; then
  log "FOUNDRY_MAX_LOGS is set: Setting maximum log count to ${FOUNDRY_MAX_LOGS}."
  set -- "$@" --maxlogs="${FOUNDRY_MAX_LOGS}"
fi

if [[ "${FOUNDRY_NO_BACKUPS:-}" == "true" ]]; then
  log "FOUNDRY_NO_BACKUPS is set to true: Disabling automatic world backups."
  set -- "$@" --nobackups
fi

if [[ "${FOUNDRY_SERVICE_KEY:-}" ]]; then
  if [[ -z "${FOUNDRY_SERVICE_CONFIG:-}" ]]; then
    log_error "FOUNDRY_SERVICE_KEY is set but FOUNDRY_SERVICE_CONFIG is not.  Both are required."
    exit 1
  fi
  log "FOUNDRY_SERVICE_KEY is set: Enabling service provider configuration."
  set -- "$@" --serviceKey="${FOUNDRY_SERVICE_KEY}"
fi

# Space separated list of regex rules which environment variables must meet to
# be carried over to the new environment, which Node/Foundry will be running in.
ENV_VAR_PASSLIST_REGEX='^HOME$ ^NODE_.+$ ^TZ$ .+_(PROXY|proxy)$'
# Build list of environment variables to carry over into a clean environment.
# An array keeps values containing spaces (e.g. NODE_OPTIONS="--a --b") as
# single NAME=VALUE arguments to env.
ENV_VAR_CARRY=()
# shellcheck disable=SC3045
# busybox read supports the -rd option
while IFS='=' read -rd '' ENV_VAR_NAME ENV_VAR_VALUE; do
  for VAR_REGEX in $ENV_VAR_PASSLIST_REGEX; do
    if [[ $ENV_VAR_NAME =~ ${VAR_REGEX} ]]; then
      ENV_VAR_CARRY+=("${ENV_VAR_NAME}=${ENV_VAR_VALUE}")
      break
    fi
  done
done < <(env -0)

# Exec node with clean environment to prevent credential leaks
log "Starting Foundry Virtual Tabletop."
# ${arr[@]+...} guards the empty-array case under `set -o nounset` on bash <4.4
exec env -i ${ENV_VAR_CARRY[@]+"${ENV_VAR_CARRY[@]}"} /usr/local/bin/node "$@" || log_error "Exec failed with code $?"
