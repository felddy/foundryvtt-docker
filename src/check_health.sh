#!/bin/sh
# shellcheck disable=SC3010
# SC3010 - busybox supports [[ ]]

if [[ "${FOUNDRY_SSL_CERT:-}" && "${FOUNDRY_SSL_KEY:-}" ]]; then
  protocol="https"
else
  protocol="http"
fi

if [[ "${FOUNDRY_ROUTE_PREFIX:-}" ]]; then
  STATUS_URL="${protocol}://localhost:30000/${FOUNDRY_ROUTE_PREFIX}/api/status"
else
  STATUS_URL="${protocol}://localhost:30000/api/status"
fi

/usr/bin/curl --cookie-jar healthcheck-cookiejar.txt \
  --cookie healthcheck-cookiejar.txt --insecure --fail --silent \
  "${STATUS_URL}" || exit 1
