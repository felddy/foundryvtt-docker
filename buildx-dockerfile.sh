#!/usr/bin/env bash

# Create a Dockerfile suitable for a multi-platform build using buildx
# See: https://docs.docker.com/buildx/working-with-buildx/

set -o nounset
set -o errexit
set -o pipefail

DOCKERFILE=Dockerfile
DOCKERFILEX=Dockerfile-x

# We don't want this expression to expand.
# shellcheck disable=SC2016
sed 's/^FROM /FROM --platform=$TARGETPLATFORM /g' < $DOCKERFILE > $DOCKERFILEX
