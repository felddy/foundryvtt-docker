#! /bin/bash

if [[ "${CONTAINER_PATCH_URLS:-}" ]]; then
  source logging.sh

  log_warn "CONTAINER_PATCH_URLS is set:  Only use patch URLs from trusted sources!"
  for url in ${CONTAINER_PATCH_URLS}; do
    log "Downloading patch from URL: $url"
    patch_file=$(mktemp -t patch_url.sh.XXXXXX)
    curl --silent --output "${patch_file}" "${url}"
    log_debug "Sourcing patch file: ${patch_file}"
    # shellcheck disable=SC1090
    source "${patch_file}"
  done
  log "Completed URL patching."
fi
