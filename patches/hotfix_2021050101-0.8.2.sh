#!/bin/sh

# Hotfix 0.8.2b
# ----------------------------------------------
# Hello everyone, I have prepared a hotfix which resolves several issues in the
# 0.8.2 alpha update which are blocking developers from updating systems and
# modules. Please download the attached .zip file and extract it within your
# 0.8.2 installation location under the resources/app folder.
#
# Your Foundry VTT server needs to be restarted after applying this fix for the
# changes to take effect.
#
# The changes applied by this hotfix address the following issues:
# 1. Packages being required to have lower-case names
# 2. Embedded item creation failing
# 3. Modules with implicit dependencies failing to load
# 4. ActiveEffect creation failing in the absence of an explicit duration object
# 5. ChatMessages failing creation if created using a dice rolling chat command
# 6. Rich HTML data missing from created chat messages
# 7. Fix an issue with language localization file loading
#
# Please stay tuned to the 0.8.3 milestone
# https://gitlab.com/foundrynet/foundryvtt/-/milestones/75 for other known
# issues.

PATCH_DEST="$FOUNDRY_HOME/resources/app"
PATCH_DOC_URL="https://discord.com/channels/170995199584108546/837748479706005594/838210536692252712"
PATCH_NAME="Hotfix 2021050101 for 0.8.2"
PATCH_URL="https://cdn.discordapp.com/attachments/837748479706005594/838210536470478859/hotfix-0.8.2b.zip"
TARGET_FOUNDRY_VERSION="0.8.2"

if [ "$FOUNDRY_VERSION" = "$TARGET_FOUNDRY_VERSION" ]; then
  log "Applying \"${PATCH_NAME}\""
  log "See: ${PATCH_DOC_URL}"
  patch_zip=$(mktemp -t patch_zip.XXXXXX)
  curl --output "${patch_zip}" "${PATCH_URL}" 2>&1 | tr "\r" "\n"
  # The zip file contains a root folder called "hotfix-0.8.2b"
  # Creating a symlink of the same name allows us to emulate --strip-components
  ln -snf "${PATCH_DEST}" /tmp/hotfix-0.8.2b
  unzip -o -d /tmp "${patch_zip}"
  rm /tmp/hotfix-0.8.2b "${patch_zip}"
else
  log_warn "Not applying \"${PATCH_NAME}\".  This patch is targeted for Foundry Virtual Tabletop ${TARGET_FOUNDRY_VERSION}"
fi
