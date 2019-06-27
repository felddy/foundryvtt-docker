#!/usr/bin/env bash

# Push the README.md file to the docker hub repository

# Requires the following environment variables to be set:
# DOCKER_PW, DOCKER_USER, IMAGE_NAME

set -o nounset
set -o errexit
set -o pipefail

token=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "'"$DOCKER_USER"'", "password": "'"$DOCKER_PW"'"}' \
  https://hub.docker.com/v2/users/login/ | jq -r .token)

code=$(jq -n --arg msg "$(<README.md)" \
  '{"registry":"registry-1.docker.io","full_description": $msg }' | \
      curl -s -o /dev/null  -L -w "%{http_code}" \
         https://cloud.docker.com/v2/repositories/"${IMAGE_NAME}"/ \
         -d @- -X PATCH \
         -H "Content-Type: application/json" \
         -H "Authorization: JWT ${token}")

if [[ "${code}" = "200" ]]; then
  printf "Successfully pushed README to Docker Hub"
else
  printf "Unable to push README to Docker Hub, response code: %s\n" "${code}"
  exit 1
fi
