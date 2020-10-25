#!/bin/sh

# shellcheck disable=SC2039
# busybox supports more features than POSIX /bin/sh

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
  --cookie healthcheck-cookiejar.txt --fail --silent "${STATUS_URL}" || exit 1
