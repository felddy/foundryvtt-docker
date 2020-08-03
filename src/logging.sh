#!/bin/sh
# shellcheck disable=SC2039
# busybox supports more features than POSIX /bin/sh

# Define terminal colors for use in logger functions
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"
YELLOW="\e[33m"

# Mimic the winston logging used in logging.js
log(){
  echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${GREEN}info${RESET}] $*"
}

log_warn(){
  echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${YELLOW}warn${RESET}] $*"
}

log_error(){
  echo -e "${LOG_NAME} | $(date +%Y-%m-%d\ %H:%M:%S) | [${RED}error${RESET}] $*"
}
