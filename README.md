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
    docker run --rm -v $(pwd):/pkg linz-deb-builder:$DISTRIBUTION

On success, the packages will be found under the build-area/ directory
of the source tree.

If you also want packages to be published to linz repository, pass
packagecloud token and target repository as environment variables:

    repo=dev # or "test"
    docker run --rm -v $(pwd):/pkg \
           -e PUBLISH_TO_REPOSITORY=${repo} \
           -e PACKAGECLOUD_TOKEN=${token} \
           linz-deb-builder:$DISTRIBUTION

On success, the packages will be also found on:

    https://packagecloud.io/linz/${repo}

## Use of the github action

If you want a github workflow to take care of building packages
you just need to use this action after using a checkout action.
For example:

    steps:
    - uses: actions/checkout@v1
    - uses: linz/linz-software-repository@v1

The default action only builds the packages, if you want to also
publish them you'll need to pass appropriate parameters, like:

    steps:
    - uses: actions/checkout@v1
    - uses: linz/linz-software-repository@v1
      with:
        packagecloud_token: ${{ secrets.PACKAGECLOUD_TOKEN }}
        publish_to_repository: 'dev' # or 'test'

## More info

For more info, see
https://github.com/linz/linz-software-repository/wiki/Debian-packaging

