#!/bin/bash
###
### Use the Docker Registry HTTP API v2 to query known tags for specified images
###   https://docs.docker.com/registry/spec/api/
###
### Usage:
###   docker-query-image-tags.sh <image1> (<image2> ...)
###
### Unauthenticated users still have access to an API endpoint
###   https://registry.hub.docker.com/v2/repositories/library/<image>/tags/
###
### Authenticated users can get the list from:
###   https://registry.hub.docker.com/v2/<image>/tags/list/
###

# Bash configuration
# Stop on errors, safe handling, extend globbing
set -e
set -u
set -o pipefail
shopt -s extglob

# Define the default registry endpoint
DOCKER_REGISTRY="${DOCKER_REGISTRY:-https://registry.hub.docker.com/v2/repositories/library}"

CMD_CURL=$(which curl)
if [ ! -x "${CMD_CURL}" ]; then
    echo "ERROR: Cannot find an executable curl command!"
    exit 1
fi

echo "==> Querying Docker Registry base API URL: ${DOCKER_REGISTRY}"
for _image in $* ;do
    _QUERY_URL="${DOCKER_REGISTRY}/${_image}/tags/"
    _JSON=$("${CMD_CURL}" -sSL "${_QUERY_URL}")
    if [ "$?" ]; then
        _TAGS=$(echo ${_JSON} |sed -E -e 's/^\{"count":.+"results": \[(.+)\]\}$/\1/' -e 's/\{"name": "([^"]+)"[^\}]+\},?/\1/g')
        echo "${_image}:"
        echo "    ${_TAGS}"
    else
        _ERR=$?
        echo "ERROR: Query failed, aborting. Check for site availability and API changes."
        exit ${_ERR}
    fi
done
