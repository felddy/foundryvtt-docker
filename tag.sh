#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

version=$(./bump_version.sh show)

git tag "v$version" && git push --tags
