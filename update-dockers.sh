#!/bin/bash
###
### update-dockers.sh -- Maintenance script to update a set of docker images
###
### Loads a .cfg file with one image per line (commented lines are ignored)
### For each found image, attempt to 'docker pull' that image to force a refresh
### After all images have been pulled, delete dangling images that are no longer referenced
###   (in-use layers will error on this)
###
### Set CMD_DOCKER to point to the docker binary
### Set CONFIG_DOCKER_IMAGE_LIST to the file with list of images to update;
###     defaults to ${HOME}/.config/docker-image-list.cfg
###     script commmand
###

# Bash configuration
# Stop on errors, safe handling, extend globbing
set -e
set -u
set -o pipefail
shopt -s extglob

# Default configuration
CMD_DOCKER="${CMD_DOCKER:-/usr/local/bin/docker}"
CONFIG_DOCKER_IMAGE_LIST="${CONFIG_DOCKER_IMAGE_LIST:-${HOME}/.config/docker-image-list.cfg}"

function load_image_list () {
    IMAGE_FILE="${1:-${CONFIG_DOCKER_IMAGE_LIST}}"
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
    ${CMD_DOCKER} pull ${image}
}

function prune_dangling_images () {
    local DANGLERS=$(${CMD_DOCKER} images --filter "dangling=true" -q)
    if [ ! -z "${DANGLERS}" ]; then
        echo "    Pruning: ${DANGLERS}"
        set +e
        ${CMD_DOCKER} rmi "${DANGLERS}"
        set -e
    else
        echo "    No dangling images found."
    fi
}

# Load list of images to be updated
# Use command-line argument if one was provided
# Othewrise use CONF_DOCKER_IMAGE_LIST
declare -a IMAGE_LIST
_IMAGE_LIST_FILE="${1:-${CONFIG_DOCKER_IMAGE_LIST}}"
echo "==> Updating list from ${_IMAGE_LIST_FILE}..."
load_image_list "${_IMAGE_LIST_FILE}"
echo "    ${#IMAGE_LIST[@]} images requested"

for image in "${IMAGE_LIST[@]}"; do
  echo "--> Processing ${image}"
  update_image "${image}"
done

# Prune dangling (unused) images
echo "==> Pruning dangling images"
prune_dangling_images

echo "=== Done."
