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

DIST=$(lsb_release -cs)
CURBRANCH=$(git rev-parse --abbrev-ref HEAD)
BUILDBRANCH=pkg-build-dist-$DIST-$(date +%s)

git branch "$BUILDBRANCH"
git checkout "$BUILDBRANCH"

dch \
    --newversion "$(git tag --sort=version:refname | grep -v debian | tail -n 1)-1linz~${DIST}1" \
    --distribution "$DIST" \
    "Package rebuild for $DIST"

git add debian/changelog
git commit -m "Debian changelog update for package rebuild"

gbp buildpackage \
    -i.git -I.git \
    --git-export-dir=build-area \
    --git-builder=debuild \
    --git-no-pristine-tar \
    --git-upstream-tag='%(version)s' \
    --git-ignore-branch \
    --git-ignore-new \
    --git-tag \
    -b -us -uc

git checkout "$CURBRANCH"
git branch -D "$BUILDBRANCH"
