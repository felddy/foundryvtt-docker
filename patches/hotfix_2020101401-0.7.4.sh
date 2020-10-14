#!/bin/sh

# Experimental Hotfix
# =====================
# Dealing with packages (worlds/systems/modules) which have invalid language
# declarations.
# There have been more cases than I expected of modules which declare an invalid
# languages in their manifest, which causes unanticipated failures in FVTT's
# initialization process. If you are stuck with that issue, applying the
# following patch will bypass the problem and produce some logging in the
# error.log file highlighting which module(s) are the culprits.

PATCH_DEST="$FOUNDRY_HOME/resources/app/dist/packages/package.js"
PATCH_DOC_URL="https://discordapp.com/channels/170995199584108546/765691837938663484/765962667721883659"
PATCH_NAME="Experimental Hotfix 2020101401 for 0.7.4"
PATCH_URL="https://cdn.discordapp.com/attachments/765691837938663484/765962667772739614/package.js"
TARGET_FOUNDRY_VERSION="0.7.4"

if [ "$FOUNDRY_VERSION" = "$TARGET_FOUNDRY_VERSION" ]; then
  log "Applying \"${PATCH_NAME}\""
  log "See: ${PATCH_DOC_URL}"
  curl --output "${PATCH_DEST}" "${PATCH_URL}" 2>&1 | tr "\r" "\n"
else
  log_warn "Not applying \"${PATCH_NAME}\".  This patch is targeted for Foundry Virtual Tabletop ${TARGET_FOUNDRY_VERSION}"
fi
