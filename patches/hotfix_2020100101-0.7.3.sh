#!/bin/sh

# Experimental Hotfix
# =====================
# Beta 0.7.3 Fixes for Testing (#2)
# Hey folks, I've been able to address a number of key issues reported thus-far
# related to the 0.7.3 beta version. The attached and updated client code will
# address these issues and allow you to continue testing 0.7.3 more effectively.
#
# In particular, this fix addresses:
# 1. Framerate improvements with large light sources
# 2. Scene offsets for shift-x and shift-y which caused fog/vision to be
#    incorrectly masked
# 3. Chroma animation failures.
# 4. Auto-toggling of global illumination with the threshold value on the
#    darkness slider.
# 5. A number of other fixes as listed in the "Closed" column of the 0.7.4
#    milestone: https://gitlab.com/foundrynet/foundryvtt/-/milestones/63

PATCH_DEST="$FOUNDRY_HOME/resources/app/public/scripts/foundry.js"
PATCH_DOC_URL="https://discordapp.com/channels/170995199584108546/760675730848743435/761380315720974386"
PATCH_NAME="Experimental Hotfix 2020101001 for 0.7.3"
PATCH_URL="https://cdn.discordapp.com/attachments/760675730848743435/761380315419115570/foundry.js"
TARGET_FOUNDRY_VERSION="0.7.3"

if [ "$FOUNDRY_VERSION" = "$TARGET_FOUNDRY_VERSION" ]; then
  log "Applying \"${PATCH_NAME}\""
  log "See: ${PATCH_DOC_URL}"
  curl --output "${PATCH_DEST}" "${PATCH_URL}" 2>&1 | tr "\r" "\n"
else
  log_warn "Not applying \"${PATCH_NAME}\".  This patch is targeted for Foundry Virtual Tabletop ${TARGET_FOUNDRY_VERSION}"
fi
