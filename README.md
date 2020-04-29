# Management of LINZ's Software Repository

The goal of this project is to offer tools to build software packages
to deploy on server and desktop machines.

What's provided is a Docker image, a github action and instructions to
use either one as a common environment for building ubuntu packages.

## Direct use of docker image from 

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

### Using the docker image to build packages for a given LINZ software

Just invoke the docker container specifying where it can find the
root source dir of the software to build packages for:

    # From directory of software to build:
    docker run --rm -v $(pwd):/pkg linz-deb-builder:$DISTRIBUTION

On success, the packages will be found under the build-area/ directory
of the source tree.

## Use of the github action

If you want a github workflow to take care of building packages
you just need to use this action after using a checkout action.
For example:

    steps:
    - uses: actions/checkout@v1
    - uses: linz/linz-software-repository@v1

## More info

For more info, see
https://github.com/linz/linz-software-repository/wiki/Debian-packaging

