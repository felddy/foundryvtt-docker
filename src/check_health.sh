#!/bin/sh

if [ "${FOUNDRY_ROUTE_PREFIX:-}" ]; then
  STATUS_URL="http://localhost:30000/${FOUNDRY_ROUTE_PREFIX}/api/status"
else
  STATUS_URL="http://localhost:30000/api/status"
fi

/usr/bin/curl --cookie-jar healthcheck-cookiejar.txt \
  --cookie healthcheck-cookiejar.txt --fail --silent "${STATUS_URL}" || exit 1
