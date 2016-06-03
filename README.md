# Docker Utilities

Miscellaneous mostly-simple utilities to support a Docker host.

| Utility | Short Description |
| ------- | ----------------- |
| run-docker-bench-test.sh | Check Docker environment against security benchmarks. |
| update-dockers.sh | Update pre-defined list of Docker images |

## run-docker-bench-test.sh

Runs the [docker-bench-test](https://github.com/gaia-adm/docker-bench-test) scripts in a pre-packaged Docker image. Based on the Docker [docker-bench-security tests](https://github.com/docker/docker-bench-security) and the [Center for Internet Security's Docker Benchmarks](https://benchmarks.cisecurity.org/downloads/browse/index.cfm?category=benchmarks.servers.virtualization.docker).

By default, this script pulls the latest image, runs the tests, and removes the container. Tests are retained in a working directory on the host.

The following environmental variables will affect the runtime:
* `DOCKER` path to Docker binary (default: `/usr/bin/docker`)
* `DOCKER_BENCH_TEST_IMAGE` name of docker-bench-test image (default: `gaiadm/docker-bench-test`)
* `DOCKER_BENCH_TEST_WORKDIR` working directory for bench-test, including the `config`, `results`, and `tests` sub-directories (default: `/var/docker-bench-test`)
* `DOCKER_BENCH_TEST_LABEL` label to apply to the container (default: `docker_bench_test`)
* `DOCKER_BENCH_TEST_NOAUTORM` if set, keeps the container after running (i.e., doesn't pass `--rm` to `docker run)`
* `DOCKER_BENCH_TEST_NOAUTOUPDATE` if set, does not update the image before starting (i.e., no `docker pull`)

## update-dockers.sh

Updates a configured list of images to ensure the latest available version of the specified image is available.

By default, after updates, the script purges any un-referenced layers from legacy images to reclaim disk space.

The following environmental variables will affect the runtime:
* `DOCKER` path to Docker binary (default: `/usr/bin/docker`)
* `DOCKER_IMAGE_UPDATE_LIST` file containing list of images to be updated (pulled) (default: `$HOME/.config/docker-image-list.cfg`)
* `DOCKER_IMAGE_UPDATE_NOPURGE` if set, does not purge dangling image files
