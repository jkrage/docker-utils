#!/bin/bash
###
### run-docker-bench-test.sh -- Run security evaluation on docker installation
###
### Note, default volume mappings presume Linux with systemd
###
### From https://github.com/gaia-adm/docker-bench-test.git
### Based on CIS Docker Benchmark (cisecurity.org) and Docker's docker-bench
###
### Supported environmental variables:
###     DOCKER to point to the docker binary
###     DOCKER_BENCH_TEST_IMAGE to the proper image (e.g., gaiaadm/docker-bench-test:latest)
###     DOCKER_BENCH_TEST_WORKDIR to the test result output directory
###     DOCKER_BENCH_TEST_LABEL to the desired container label
###     DOCKER_BENCH_TEST_NOAUTORM to retain the container (if unset, uses docker --rm)
###     DOCKER_BENCH_TEST_NOAUTOUPDATE to skip automatic docker pull
###

# Bash configuration
# Stop on errors, safe handling, extend globbing
set -e
set -u
set -o pipefail
shopt -s extglob

# Defaults configuration
DOCKER="${DOCKER:-/usr/bin/docker}"
DOCKER_BENCH_TEST_IMAGE="${DOCKER_BENCH_TEST_IMAGE:-gaiaadm/docker-bench-test}"
DOCKER_BENCH_TEST_WORKDIR="${DOCKER_BENCH_TEST_WORKDIR:-/var/docker-bench-test}"
DOCKER_BENCH_TEST_LABEL="${DOCKER_BENCH_TEST_LABEL:-docker_bench_test}"
if [ -z "${DOCKER_BENCH_TEST_NOAUTORM+x}" ]; then
    _autorm="--rm"
else
    _autorm=""
fi
LATEST_TEST="results/tests_latest.tap"

# Update the container to the latest by default
if [ -z "${DOCKER_BENCH_TEST_NOAUTOUPDATE+x}" ]; then
    echo "==> Pulling latest version of: ${DOCKER_BENCH_TEST_IMAGE}"
    ${DOCKER} pull "${DOCKER_BENCH_TEST_IMAGE}"
else
    echo "==> Skipping image update of: ${DOCKER_BENCH_TEST_IMAGE}"
fi
${DOCKER} images --digests "${DOCKER_BENCH_TEST_IMAGE}"

echo "==> Commencing test runs..."
${DOCKER} run -it "${_autorm}" \
    --net host \
    --pid host \
    --cap-add audit_control \
    -v /var/lib:/var/lib \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/lib/systemd:/usr/lib/systemd \
    -v "${DOCKER_BENCH_TEST_WORKDIR}:/var/docker-bench-test" \
    -v /etc:/host/etc \
    --label "${DOCKER_BENCH_TEST_LABEL}" \
    "${DOCKER_BENCH_TEST_IMAGE}"

echo "==> Testing complete, results directory: ${DOCKER_BENCH_TEST_WORKDIR}"
ls -lh "${DOCKER_BENCH_TEST_WORKDIR}/${LATEST_TEST}"
