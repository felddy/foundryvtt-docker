#!/bin/sh

# Issue Hotfix
# =====================
# Corrects routePrefix problem detailed in issue 3817
# https://gitlab.com/foundrynet/foundryvtt/-/issues/3817

PATCH_DEST="$FOUNDRY_HOME/resources/app/public/scripts/foundry.js"
PATCH_DOC_URL="https://gitlab.com/foundrynet/foundryvtt/-/issues/3817#note_430588341"
PATCH_NAME="Issue 3817 Hotfix for 0.7.4"
TARGET_FOUNDRY_VERSION="0.7.4"

if [ "$FOUNDRY_VERSION" = "$TARGET_FOUNDRY_VERSION" ]; then
  log "Applying \"${PATCH_NAME}\""
  log "See: ${PATCH_DOC_URL}"
  sed --file=- --in-place=.orig "${PATCH_DEST}" << SED_SCRIPT
s/const view = url\.pathname\.replace(\`\/\${ROUTE_PREFIX}\`, "");\
/const view = url.pathname.split("\/").pop();/g
SED_SCRIPT
else
  log_warn "Not applying \"${PATCH_NAME}\".  This patch is targeted for Foundry Virtual Tabletop ${TARGET_FOUNDRY_VERSION}"
fi
