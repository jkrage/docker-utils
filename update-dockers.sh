#!/bin/bash
###
### update-dockers.sh -- Maintenance script to update a set of docker images
###
### Loads a .cfg file with one image per line (commented lines are ignored)
### For each found image, attempt to 'docker pull' that image to force a refresh
### After all images have been pulled, delete dangling images that are no longer referenced
###   (in-use layers will error on this)
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
DOCKER_IMAGE_UPDATE_LIST="${DOCKER_IMAGE_UPDATE_LIST:-${HOME}/.config/docker-image-list.cfg}"

# Enable Docker content trust
export DOCKER_CONTENT_TRUST=1

function load_image_list () {
    IMAGE_FILE="${1:-${DOCKER_IMAGE_UPDATE_LIST}}"
    if [ ! -r "${IMAGE_FILE}" ]; then
        echo "ERROR: Image list ${IMAGE_FILE} is not readable (or does not exist)."
        exit 1
    fi
    # Load list of images to process from a config file
    while read image_line ;do
        # Skip comments
        image_line="${image_line##*([:space:])#*}"
        if [ ! -z "${image_line}" ]; then
            IMAGE_LIST+=("${image_line}")
        fi
    done <"${IMAGE_FILE}"
}

function update_image () {
    image=${1:-""}
    set +e
    if ! output=$(${DOCKER} pull "${image}" 2>&1 >/dev/null) ; then
        echo "${output}"
    fi
    set -e
}

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

# Load list of images to be updated
# Use command-line argument if one was provided
# Otherwise use CONF_DOCKER_IMAGE_UPDATE_LIST
declare -a IMAGE_LIST
_IMAGE_LIST_FILE="${1:-${DOCKER_IMAGE_UPDATE_LIST}}"
load_image_list "${_IMAGE_LIST_FILE}"
echo "==> Updating ${#IMAGE_LIST[@]} images listed in ${_IMAGE_LIST_FILE}"

for image in "${IMAGE_LIST[@]}"; do
  echo "--> Processing ${image}"
  update_image "${image}"
done

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
