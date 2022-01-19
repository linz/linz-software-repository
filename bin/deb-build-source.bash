#!/bin/bash

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

gbp buildpackage \
    -i.git -I.git \
    --git-export-dir=build-area \
    --git-builder=debuild \
    --git-no-pristine-tar \
    --git-upstream-tag='%(version)s' \
    --git-ignore-branch \
    --git-ignore-new \
    -S -us -uc "$@"

# vim: set ts=4 sts=4 sw=4 et:
