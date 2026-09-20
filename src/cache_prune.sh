#!/bin/bash

# cache_prune.sh — sourceable bash library for cache eviction.
# Source this file from entrypoint.sh before use.
#
# Exposes:
#   cache_prune <cache_dir> <keep_count>
#     Delete cached release archives (foundryvtt-*.zip) beyond <keep_count>,
#     keeping the most recently *used* ones.  An archive's mtime records its
#     last use: downloads set it, and the entrypoint touches the archive each
#     time a container installs from it.  Evicting by use instead of by
#     version number keeps an older major's release alive in a shared cache
#     as long as some instance still installs it (#1266).
#
#     Only files matching foundryvtt-*.zip are ever considered: in-progress
#     downloads, lock directories, and state files are never touched.
#
# Depends on logging.sh being sourced by the caller before this file.

cache_prune() {
  local cache_dir="$1"
  local keep="$2"
  local removed=0
  local file

  # Archive names are machine-generated (foundryvtt-<version>.zip) and never
  # contain whitespace, so an ls -t line is always exactly one filename.
  # ls -t (sort by mtime, newest first) is portable where find -printf and
  # stat format flags are not.
  # shellcheck disable=SC2012 # names are machine-generated, never hostile
  while IFS= read -r file; do
    log_warn "Removing least recently used cached release: ${cache_dir}/${file}"
    rm -f "${cache_dir}/${file}"
    removed=$((removed + 1))
  done < <(cd "${cache_dir}" 2> /dev/null && ls -1t foundryvtt-*.zip 2> /dev/null \
    | awk -v keep="${keep}" 'NR > keep')

  if ((removed > 0)); then
    log "Completed cache cleanup.  Removed ${removed} files."
  else
    log "No cache cleanup was necessary."
  fi
}
