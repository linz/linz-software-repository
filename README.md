[![Actions Status](https://github.com/linz/linz-software-repository/workflows/CI/badge.svg?branch=master)](https://github.com/linz/linz-software-repository/actions)

# Management of LINZ's Software Repository

The goal of this project is to offer tools to build software packages
to deploy on server and desktop machines.

What's provided is a Docker image, a github action and instructions to
use either one as a common environment for building ubuntu packages.

## Direct use of docker image

### Docker Image Preparation

Debian packaging Docker image must be built before Docker container
can be used.

To build the Debian packaging Docker image you can use the following
command:

	make image

The image will be built for a target ubuntu distribution
(see DISTRIBUTION on top of Makefile to find out which one).
Shall you need to build packages for another distribution
you can tweak set DISTRIBUTION env variable accordingly:

  DISTRIBUTION=focal make image

### Build and optionally publish packages for a given LINZ software

Just invoke the docker container specifying where it can find the
root source dir of the software to build packages for:

    # From directory of software to build:
    docker run --rm -v $(pwd):/pkg linz-deb-builder:${DISTRIBUTION}

On success, the packages will be found under the `build-area/`
directory of the source tree.

If you also want packages to be published to linz repository, pass
packagecloud token and target repository as environment variables:

    export PACKAGECLOUD_REPOSITORY=dev # or "test"
    export PACKAGECLOUD_TOKEN # set to API token
    docker run --rm -v $(pwd):/pkg \
           -e PACKAGECLOUD_REPOSITORY \
           -e PACKAGECLOUD_TOKEN \
           linz-deb-builder:${DISTRIBUTION}

On success, the packages will be also found on:

    https://packagecloud.io/linz/${repo}

When `PACKAGECLOUD_REPOSITORY` is set to `test`:

  - Changes to `debian/changelog` are committed to a temporary branch.
  - A debian git tag is created (eg. `debian/${tag}-linz~${DISTRIBUTION}`).
  - The debian tag is merged to any local and remote branch containing the
    initial HEAD reference of the source tree.
  - The debian tag is pushed to any remote having branches containing the
    initial HEAD reference of the source tree and to any remote passed
    via the `PUSH_TO_GIT_REMOTE` env variable.

Passing a `PUSH_TO_GIT_REMOTE` env variable is useful to specify
credentials to access the remote (as the docker container will not
have access to those). Example:

    export PACKAGECLOUD_REPOSITORY="test"
    export PACKAGECLOUD_TOKEN # set to API token
    export PUSH_TO_GIT_REMOTE=https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}
    docker run --rm -v $(pwd):/pkg \
           -e PACKAGECLOUD_REPOSITORY \
           -e PACKAGECLOUD_TOKEN \
           -e PUSH_TO_GIT_REMOTE \
           linz-deb-builder:${DISTRIBUTION}

If you only want to test the image without triggering any changes
to any remote (packagecloud and git remotes) you can pass the `DRY_RUN`
environment variable with any non-empty string:

    export PACKAGECLOUD_REPOSITORY="test"
    export PACKAGECLOUD_TOKEN # set to API token
    export PUSH_TO_GIT_REMOTE=https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}
    docker run --rm -v $(pwd):/pkg \
           -e PACKAGECLOUD_REPOSITORY \
           -e PACKAGECLOUD_TOKEN \
           -e PUSH_TO_GIT_REMOTE \
           -e DRY_RUN=yes \
           linz-deb-builder:${DISTRIBUTION}

## Use of the github action

If you want a github workflow to take care of building packages
you just need to use this action after using a checkout action.
For example:

    steps:
    - uses: actions/checkout@v1
    - uses: linz/linz-software-repository@v4

The default action only builds the packages.

If you want to also publish packages to packagecloud
you'll need to pass appropriate parameters:

    steps:
    - uses: actions/checkout@v1
    - uses: linz/linz-software-repository@v4
      with:
        packagecloud_token: ${{ secrets.PACKAGECLOUD_TOKEN }}
        publish_to_repository: 'dev'

When publishing to the 'test' repository you will also want
to set the "origin" url to have credentials:

    steps:
    - uses: actions/checkout@v1
    - name: Authorize pushing to remote
      run: |
        git remote set-url origin https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${GITHUB_REPOSITORY}
    - uses: linz/linz-software-repository@v4
      with:
        packagecloud_token: ${{ secrets.PACKAGECLOUD_TOKEN }}
        publish_to_repository: 'test'

## More info

For more info, see
https://github.com/linz/linz-software-repository/wiki/Debian-packaging

