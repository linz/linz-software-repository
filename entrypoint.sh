#!/bin/bash

echo "----------------------------------------------------"
echo "LINZ Software Packaging system"
echo 
echo "Arguments: $@"
echo
echo "Supported Arguments:"
echo "   <srcdir> dir containing source (defaults to /pkg)"
echo "----------------------------------------------------"
echo


SRCDIR=${1-"/pkg"}
cd ${SRCDIR} || {
  echo "Did you forget to mount package source to ${SRCDIR} ?" >&2
  exit 1
}

PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin:

echo "------------------------------"
echo "Updating Debian changelog"
echo "------------------------------"

LAST_COMMITTER_NAME=$(git --no-pager show -s --format='%cn' HEAD)
LAST_COMMITTER_EMAIL=$(git --no-pager show -s --format='%ce' HEAD)

export DEBFULLNAME="${LAST_COMMITTER_NAME}"
export DEBEMAIL="${LAST_COMMITTER_EMAIL}"

git config --global user.email "${LAST_COMMITTER_NAME}"
git config --global user.name "${LAST_COMMITTER_EMAIL}"

msg="New upstream version" #TODO: tweak this (take as param?)
tag=$(git describe --tags --exclude 'debian/*')
dist=$(lsb_release -cs)
version="${tag}-linz~${dist}1"

echo "Using version: $version"
echo "Hostname: ${HOSTNAME}"

TMPBRANCH=pkg-dev-${HOSTNAME}

git checkout -b ${TMPBRANCH} || exit 1

trap 'git checkout -' 0

dch -D ${dist} -v "${version}" "$msg" || exit 1

git diff

git commit -m "[debian] Changelog update" debian/changelog || exit 1

echo "------------------------------"
echo "Running deb-build-dependencies"
echo "------------------------------"
deb-build-dependencies || exit 1

echo "------------------------------"
echo "Running deb-build-binary"
echo "------------------------------"
deb-build-binary || exit 1

echo "-------------------------------------"
echo "List packages now in build-area/"
echo "-------------------------------------"

ls -l build-area/*.deb


#
# Check if we need to publish
#

if test -n "${PUBLISH_TO_REPOSITORY}"; then

  echo "--------------------------------------------------"
  echo "Publishing packages to ${BASE}"
  echo "--------------------------------------------------"

  if test -z "${PACKAGECLOUD_TOKEN}"; then
    echo "Cannot publish to packages without a PACKAGECLOUD_TOKEN" >&2
    exit 1;
  fi
  REPO="${PUBLISH_TO_REPOSITORY}"
  case "${REPO}" in
    dev|test)
      ;;
    *)
      echo "Invalid target linz repository ${REPO} (must be 'dev' or 'test')" >&2
      exit 1
      ;;
  esac
  BASE="linz/${REPO}/ubuntu/${dist}"
  package_cloud push ${BASE} build-area/*.deb || exit 1
fi

echo "--------------------------------------------------"
echo "You can now delete the ${TMPBRANCH} git branch"
echo "--------------------------------------------------"

