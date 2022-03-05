#!/bin/bash
###
### prune-dockers.sh -- Maintenance script to clear docker cache
###
### Set DOCKER to point to the docker binary
### Set DOCKER_IMAGE_UPDATE_LIST to the file with list of images to update;
###     defaults to ${HOME}/.config/docker-image-list.cfg
###     script commmand
### Set DOCKER_IMAGE_UPDATE_NOPURGE to skip cleanup of dangling images
###

# Bash configuration
# Stop on errors, safe handling, extend globbing
set -e
set -u
set -o pipefail
shopt -s extglob

# Default configuration
DOCKER="${DOCKER:-/usr/bin/docker}"

function prune_dangling_images () {
    local DANGLERS=$(${DOCKER} images --filter "dangling=true" -q)
    if [ ! -z "${DANGLERS}" ]; then
        set +e
        for image in ${DANGLERS}; do
            echo "    Pruning: ${image}"
            if ! output=$(${DOCKER} rmi "${image}" 2>&1 >/dev/null) ; then
                echo "${output}"
            fi
        done
        set -e
    else
        echo "    No dangling images found."
    fi
}

# Prune dangling (unused) images
if [ -z "${DOCKER_IMAGE_UPDATE_NOPURGE:+x}" ]; then
    echo
    echo "==> Pruning dangling images"
    prune_dangling_images
else
    echo
    echo "==> Skipping cleanup of dangling images"
fi

echo "=== Done."
