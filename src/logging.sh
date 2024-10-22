#!/bin/bash

# Define terminal colors for use in logger functions
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"
YELLOW="\e[33m"

# Mimic the winston logging used in logging.js
log_debug() {
  if [[ "${CONTAINER_VERBOSE:-}" ]]; then
    echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${BLUE}debug${RESET}] $*"
  fi
}

log() {
  echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${GREEN}info${RESET}] $*"
}

log_warn() {
  echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${YELLOW}warn${RESET}] $*"
}

log_error() {
  echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${RED}error${RESET}] $*"
}
