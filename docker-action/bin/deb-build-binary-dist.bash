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

dist=$(lsb_release --codename --short)
curbranch=$(git rev-parse --abbrev-ref HEAD)
buildbranch=pkg-build-dist-$dist-$(date +%s)

git branch "$buildbranch"
git checkout "$buildbranch"

last_version_tag="$(git tag --sort=version:refname | grep --invert-match debian | tail --lines=1)"
version="${last_version_tag#v}"
dch \
    --newversion "${version}-1linz~${dist}1" \
    --distribution "$dist" \
    "Package rebuild for $dist"

git add debian/changelog
git commit --message="Debian changelog update for package rebuild"

gbp buildpackage \
    --git-export-dir=build-area \
    --git-no-pristine-tar \
    --git-upstream-tag='%(version)s' \
    --git-ignore-branch \
    --git-ignore-new \
    --git-tag \
    -b -us -uc

git checkout "$curbranch"
git branch --delete --force "$buildbranch"
