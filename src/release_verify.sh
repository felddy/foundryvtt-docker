#!/bin/bash

# release_verify.sh — sourceable bash library for inspecting release archives.
# Source this file from entrypoint.sh before use.
#
# Exposes:
#   release_archive_version <archive>
#     Print the Foundry Virtual Tabletop version ("generation.build")
#     contained in a release zip and return 0.  Returns 1 when the version
#     cannot be determined (not a zip, no package.json, a pre-v9 layout, or
#     malformed metadata) — callers should treat that as "unknown", never as
#     a mismatch.
#
# Works for both release layouts: Node.js zips carry package.json at the
# archive root; Linux zips carry it under resources/app/.

release_archive_version() {
  local archive="$1"
  local member pkg version
  for member in package.json resources/app/package.json; do
    if pkg=$(unzip -p "${archive}" "${member}" 2> /dev/null) && [[ -n "${pkg}" ]]; then
      if version=$(printf '%s' "${pkg}" \
        | jq --raw-output --exit-status '.release | "\(.generation).\(.build)"' 2> /dev/null); then
        # Guard against partial metadata rendering as "null.null" etc.
        if [[ "${version}" =~ ^[0-9]+\.[0-9]+$ ]]; then
          printf '%s' "${version}"
          return 0
        fi
      fi
    fi
  done
  return 1
}
