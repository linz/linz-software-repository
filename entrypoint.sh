#!/bin/sh

set -o errexit -o nounset

release="$1"
packages="$2"

tag="linz-deb-builder"
project_name="$(basename "$GITHUB_REPOSITORY")"
host_repo_dir="${RUNNER_WORKSPACE}/${project_name}"

cd /docker-action

docker build --build-arg=DISTRIBUTION="$release" --build-arg=EXTRA_PACKAGES="$packages" --tag="$tag" .
docker run --env=PACKAGECLOUD_TOKEN --env=PACKAGECLOUD_REPOSITORY --env=PUSH_TO_GIT_REMOTE --env=DRY_RUN --volume="${host_repo_dir}:/pkg" "$tag"
