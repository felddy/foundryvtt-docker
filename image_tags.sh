#!/usr/bin/env bash

# This file is sourced by the build workflow when processing a branch or tag
# that is a semantic version.  e.g; v1.2.3-pre+5

# Its purpose is to add branch-specific tags to an image.

TAGS="${TAGS},${IMAGE_NAME}:prerelease"
