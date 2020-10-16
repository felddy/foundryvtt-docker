#!/bin/sh

# Experimental Hotfix
# =====================
# This file corrects for the two most significant issues users are having with the 0.6.4 update.
#
# Hyperlink Embedding - corrects a problem with hyperlink embedding in rich text editors.
# Wall Chaining - corrects the behavior of wall chaining which causes walls to sometimes chain from the wrong place.

PATCH_DEST="$FOUNDRY_HOME/resources/app/public/scripts/foundry.js"
PATCH_DOC_URL="https://discordapp.com/channels/170995199584108546/725021759144984646/726858730658070568"
PATCH_NAME="Experimental Hotfix 2020062801 for 0.6.4"
PATCH_URL="https://cdn.discordapp.com/attachments/725021759144984646/726858729957359668/foundry.js"
TARGET_FOUNDRY_VERSION="0.6.4"

if [ "$FOUNDRY_VERSION" = "$TARGET_FOUNDRY_VERSION" ]; then
  log "Applying \"${PATCH_NAME}\""
  log "See: ${PATCH_DOC_URL}"
  curl --output "${PATCH_DEST}" "${PATCH_URL}" 2>&1 | tr "\r" "\n"
else
  log_warn "Not applying \"${PATCH_NAME}\".  This patch is targeted for Foundry Virtual Tabletop ${TARGET_FOUNDRY_VERSION}"
fi
