#!/bin/ash
# shellcheck shell=dash

# Issue 697 Fix
# =====================
# V11 Database glibc Workaround
# In upgrading to the new database engine for v11, some devices may experience
# an error related to an invalid version of glibc. This most notably affects ARM
# architecture devices, including some models of Raspberry Pi.

PATCH_DOC_URL="https://github.com/felddy/foundryvtt-docker/issues/697"
PATCH_NAME="Fix for issue #697 - v11 database glibc workaround"

log "Applying \"${PATCH_NAME}\""
log "See: ${PATCH_DOC_URL}"

apk add g++ make python3
cd resources/app || exit
npm install classic-level --build-from-source
cd - || exit
