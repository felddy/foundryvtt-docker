#!/bin/bash

# fvtt.sh — wrapper for the Foundry Virtual Tabletop CLI, installed in the
# image as /usr/local/bin/fvtt.
#
# The CLI persists its configuration to ${XDG_DATA_HOME}/.fvttrc.yml
# (~/.local/share when unset) and creates that file on every invocation, so
# the location must be writable.  The container may run as an arbitrary UID
# whose home directory is not writable, so default the location to the /data
# volume, which the entrypoint guarantees is writable and which persists
# across container recreation.  The variable is scoped to the CLI process
# only; the Foundry server never sees it.  Set XDG_DATA_HOME to override.
#
# On first use, seed the configuration with this container's Foundry
# installation and data paths so CLI commands work without any manual
# `fvtt configure set` steps.

set -o nounset
set -o errexit
set -o pipefail

cli_main="/usr/local/lib/node_modules/@foundryvtt/foundryvtt-cli/fvtt.mjs"
if [[ ! -f "${cli_main}" ]]; then
  echo "The Foundry VTT CLI is not included in this image's $(uname -m) variant:" >&2
  echo "its classic-level dependency cannot be built for this architecture." >&2
  exit 1
fi

export XDG_DATA_HOME="${XDG_DATA_HOME:-/data/.local/share}"

# Seed through a temporary file and rename so concurrent first invocations
# never observe a partially written file, and leave the file writable by any
# UID — matching this image's /data volume conventions — so a later run under
# a different UID can still `fvtt configure set`.
config_file="${XDG_DATA_HOME}/.fvttrc.yml"
if [[ ! -f "${config_file}" ]]; then
  # umask 000: directories created here must stay writable by any UID a
  # later container run may use.  Scoped to a subshell, and pre-existing
  # directories (e.g. a user-supplied XDG_DATA_HOME) are never modified.
  (umask 000 && mkdir -p "${XDG_DATA_HOME}")
  tmp_file=$(mktemp "${config_file}.XXXXXX")
  cat << END_OF_CONFIG > "${tmp_file}"
installPath: /home/node/resources/app
dataPath: /data
END_OF_CONFIG
  chmod a+rw "${tmp_file}"
  # -n: if another invocation won the race, keep its (identical) file.
  mv -n "${tmp_file}" "${config_file}"
  rm -f "${tmp_file}"
fi

exec node "${cli_main}" "$@"
