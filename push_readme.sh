#!/usr/bin/env bash

# Push the README.md file to the Docker Hub repository

# Requires the following environment variables to be set:
# DOCKER_PASSWORD, DOCKER_USERNAME, IMAGE_NAME

set -o nounset
set -o errexit
set -o pipefail

echo "Logging in and requesting JWT..."
token=$(curl --silent --request POST \
  --header "Content-Type: application/json" \
  --data \
  '{"username": "'"$DOCKER_USERNAME"'", "password": "'"$DOCKER_PASSWORD"'"}' \
  https://hub.docker.com/v2/users/login/ | jq --raw-output .token)

echo "Pushing README file..."
code=$(jq --null-input --arg msg "$(< README.md)" \
  '{"registry":"registry-1.docker.io","full_description": $msg }' \
  | curl --silent --output /dev/null --location --write-out "%{http_code}" \
    https://hub.docker.com/v2/repositories/"${IMAGE_NAME}"/ \
    --data @- --request PATCH \
    --header "Content-Type: application/json" \
    --header "Authorization: JWT ${token}")

if [[ "${code}" = "200" ]]; then
  printf "Successfully pushed README to Docker Hub"
else
  printf "Unable to push README to Docker Hub, response code: %s\n" "${code}"
  exit 1
fi
