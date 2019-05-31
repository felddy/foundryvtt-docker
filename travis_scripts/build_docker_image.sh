#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

version=$(./bump_version.sh show)
# shellcheck disable=SC2140
docker build -t "$IMAGE_NAME":"$version" -t "$IMAGE_NAME":"latest" .
