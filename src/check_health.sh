#!/bin/bash

# Health check for the Foundry server.
#
# The effective server configuration is read from options.json — the same
# file Foundry itself reads, including changes saved through the setup UI —
# with the environment variables as a fallback.  Deciding from environment
# variables alone probed http against servers configured for https through
# the UI, leaving the container permanently unhealthy.

config_file="${DATA_DIR:-/data}/Config/options.json"

opt() {
  jq --raw-output "$1 // empty" "${config_file}" 2> /dev/null
}

ssl_cert=$(opt .sslCert)
ssl_key=$(opt .sslKey)
route_prefix=$(opt .routePrefix)
unix_socket=$(opt .unixSocket)
port=$(opt .port)

ssl_cert="${ssl_cert:-${FOUNDRY_SSL_CERT:-}}"
ssl_key="${ssl_key:-${FOUNDRY_SSL_KEY:-}}"
route_prefix="${route_prefix:-${FOUNDRY_ROUTE_PREFIX:-}}"
unix_socket="${unix_socket:-${FOUNDRY_UNIX_SOCKET:-}}"
port="${port:-30000}"

if [[ "${ssl_cert}" && "${ssl_key}" ]]; then
  protocol="https"
else
  protocol="http"
fi

curl_args=(
  --cookie-jar /tmp/healthcheck-cookiejar.txt
  --cookie /tmp/healthcheck-cookiejar.txt
  --insecure --fail --silent
)

if [[ "${unix_socket}" ]]; then
  # A unix-socket server has no TCP port to probe; curl needs the socket
  # path and a dummy host in the URL.
  curl_args+=(--unix-socket "${unix_socket}")
  STATUS_URL="http://localhost${route_prefix:+/${route_prefix}}/api/status"
else
  STATUS_URL="${protocol}://localhost:${port}${route_prefix:+/${route_prefix}}/api/status"
fi

curl "${curl_args[@]}" "${STATUS_URL}" || exit 1
