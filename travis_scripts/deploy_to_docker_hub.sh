#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

echo "$DOCKER_PW" | docker login -u "$DOCKER_USER" --password-stdin
version=$(./bump_version.sh show)
docker push "$IMAGE_NAME":"$version"
