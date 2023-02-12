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

gbp buildpackage \
    -i.git -I.git \
    --git-export-dir=build-area \
    --git-builder=debuild \
    --git-no-pristine-tar \
    --git-upstream-tag='%(version)s' \
    --git-ignore-branch \
    --git-ignore-new \
    -b -us -uc "$@"
