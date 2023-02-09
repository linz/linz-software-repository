#!/usr/bin/env bash

################################################################################
#
# Copyright 2013 Crown copyright (c)
# Land Information New Zealand and the New Zealand Government.
# All rights reserved
#
# This program is released under the terms of the new BSD license. See the
# LICENSE file for more information.
#
################################################################################

set -o errexit -o noclobber -o nounset -o pipefail
shopt -s failglob inherit_errexit

test -f debian/control || {
    echo "Cannot find debian/control file" >&2
    exit 1
}

# TODO: Should this really be here ? I'd think NOT !
apt-get --allow-unauthenticated update

mk-build-deps \
    -i \
    -r \
    -t 'apt-get -y --allow-unauthenticated' \
    debian/control
