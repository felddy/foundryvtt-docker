#!/bin/sh

# [Optional] Hotfix #2 for 0.7.8 build
# ----------------------------------------------
# Hello all, I have update the previously posted hotfix which corrects several
# minor/moderate issues in the 0.7.8 build.
#
# Included Fixes
#
# 1. Dice formula without an explicit number of dice (i.e. /roll d6) to roll now
# fail after changes to support parenthetical evaluation of variable dice number
# in 0.7.8
#
# 2. An error occurs when changing the value of the "device pixel resolution"
# setting where the window fails to reload as the reload method is not invoked
# correctly.
#
# 3. A regression caused by assigning PIXI.settings.FILTER_RESOLUTION to a value
# greater than 1 which breaks the rendering of light source meshes.
#
# 4. Initial data cleaning performed upon Token instantiation incorrectly
# assumed that the Token belongs to the Scene currently rendered on the game
# canvas. This resulted in the migration constraining the Token position to the
# bounds of a different Scene.

PATCH_DEST="$FOUNDRY_HOME/resources/app/public/scripts/foundry.js"
PATCH_DOC_URL="https://discord.com/channels/170995199584108546/784244473261588480/788132162754183190"
PATCH_NAME="Experimental Hotfix 2020121401 for 0.7.8"
PATCH_URL="https://cdn.discordapp.com/attachments/784244473261588480/788132162536472636/foundry.js"
TARGET_FOUNDRY_VERSION="0.7.8"

if [ "$FOUNDRY_VERSION" = "$TARGET_FOUNDRY_VERSION" ]; then
  log "Applying \"${PATCH_NAME}\""
  log "See: ${PATCH_DOC_URL}"
  curl --output "${PATCH_DEST}" "${PATCH_URL}" 2>&1 | tr "\r" "\n"
else
  log_warn "Not applying \"${PATCH_NAME}\".  This patch is targeted for Foundry Virtual Tabletop ${TARGET_FOUNDRY_VERSION}"
fi
