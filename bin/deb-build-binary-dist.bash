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

dist=$(lsb_release -cs)
curbranch=$(git rev-parse --abbrev-ref HEAD)
buildbranch=pkg-build-dist-$dist-$(date +%s)

git branch "$buildbranch"
git checkout "$buildbranch"

dch \
    --newversion "$(git tag --sort=version:refname | grep -v debian | tail -n 1)-1linz~${dist}1" \
    --distribution "$dist" \
    "Package rebuild for $dist"

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

git checkout "$curbranch"
git branch -D "$buildbranch"
