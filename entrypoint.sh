#!/bin/bash

echo "----------------------------------------------------"
echo "LINZ Software Packaging system"
echo 
echo "Arguments: $@"
echo
echo "Supported Arguments:"
echo "   <srcdir> dir containing source (defaults to /pkg)"
echo
echo "Supported Environment Variables:"
echo "   PUBLISH_TO_REPOSITORY [${PUBLISH_TO_REPOSITORY}]"
echo "      Packagecloud repository to push packages to."
echo "      Can be 'test', 'dev' or empty (default)"
echo "      for not publishing them at all."
echo "      Targetting 'test' also creates a debian tag"
echo "      and pushes changes to determined git remote"
echo "   PUSH_TO_GIT_REMOTE [${PUSH_TO_GIT_REMOTE}]"
echo "      Git remote name or URL to push debian tag and"
echo "      changes to, if PUBLISH_TO_REPOSITORY=test."
echo "      Defaults to the remote containing HEAD ref."
echo "----------------------------------------------------"
echo


SRCDIR=${1-"/pkg"}
cd ${SRCDIR} || {
  echo "Did you forget to mount package source to ${SRCDIR} ?" >&2
  exit 1
}

PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin:

TMPBRANCH=pkg-dev-${HOSTNAME}

cleanup() {
  echo "--------------------------------------------------"
  echo "Checking out previous branch"
  echo "--------------------------------------------------"
  git checkout -

  echo "--------------------------------------------------"
  echo "Removing temporary branch"
  echo "--------------------------------------------------"
  git branch -D ${TMPBRANCH}
}

echo "------------------------------"
echo "Extract git information"
echo "------------------------------"

#echo "# git status"
#git status
#echo "# git remote"
#git remote
#echo "# git show-ref"
#git show-ref
#echo "# git branch --contains HEAD"
#git branch --contains HEAD
#echo "# git branch -r --contains HEAD"
#git branch -r --contains HEAD
#echo "# env | grep GITHUB"
#env | grep GITHUB

echo "# git branch -a --contains HEAD"
git branch -a --contains HEAD

REMOTE_BRANCH=$( git branch -r --contains ${HEAD} | head -1 | tr -d ' ')
echo "Remote branch containing HEAD: ${REMOTE_BRANCH}"

REMOTE_NAME=$( echo "${REMOTE_BRANCH}" | sed 's@^ *@@;s@/.*@@' )
echo "Remote containing HEAD: ${REMOTE_NAME}"

GIT_REMOTE=${PUSH_TO_GIT_REMOTE:-${REMOTE_NAME}}
echo "Remote we'll be pushing to, if needed: ${GIT_REMOTE}"

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
debian_revision=1 # TODO: take as parameter ?
version="${tag}-${debian_revision}linz~${dist}1"

echo "Using version: $version"
echo "Hostname: ${HOSTNAME}"

git checkout -b ${TMPBRANCH} || exit 1

trap 'cleanup' 0

dch -D ${dist} -v "${version}" "$msg" || exit 1

git commit -m "[debian] Changelog update" debian/changelog || exit 1

git show --pretty=fuller || exit 1

echo "-------------------------------------"
echo "Cleaning up build-area/"
echo "-------------------------------------"

rm -vrf build-area/

echo "------------------------------"
echo "Running deb-build-dependencies"
echo "------------------------------"
deb-build-dependencies || exit 1

echo "------------------------------"
echo "Running deb-build-binary"
echo "------------------------------"
DEB_BUILD_BINARY_ARGS=
if test "${PUBLISH_TO_REPOSITORY}" = "test"; then
  DEB_BUILD_BINARY_ARGS=--git-tag
fi
deb-build-binary ${DEB_BUILD_BINARY_ARGS} > log.deb-build-binary ||
{
  cat log.deb-build-binary;
  exit 1
}

# If tags are created, we'd get a message like this:
#
# gbp:info: Tagging Debian package 1.10.1-1-ga857db0-linz~bionic1 as debian/1.10.1-1-ga857db0-linz_bionic1 in git
#
GIT_TAG=$(
  grep 'Tagging Debian package .* as debian/' log.deb-build-binary |
  sed 's@.* as debian/@debian/@;s@ in git$@@'
)
if test -n "${GIT_TAG}"; then
  echo "GIT TAG ${GIT_TAG} created"
fi

echo "-------------------------------------"
echo "List packages now in build-area/"
echo "-------------------------------------"

ls -l build-area/*.deb


#
# Check if we need to publish
#

if test -n "${PUBLISH_TO_REPOSITORY}"; then

  echo "--------------------------------------------------"
  echo "Publishing packages to packagecloud ${REPO}"
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

if test -n "${GIT_TAG}"; then

  if test -n "${GIT_REMOTE}"; then

    echo "--------------------------------------------------"
    echo "Pushing tag ${GIT_TAG} to ${GIT_REMOTE}"
    echo "--------------------------------------------------"
    git push "${GIT_REMOTE}" ${GIT_TAG}:${GIT_TAG} || exit 1

    echo "--------------------------------------------------"
    echo "Pushing packaging changes to ${REMOTE_BRANCH}"
    echo "--------------------------------------------------"
    BRANCH=$(echo "${REMOTE_BRANCH}" | sed "s@${REMOTE_NAME}/@@")
    echo "Remote branch name: ${REMOTE_BRANCH}"
    echo "Remote name: ${REMOTE_NAME}"
    echo "Branch name: ${BRANCH}"
    git push "${GIT_REMOTE}" ${TMPBRANCH}:${BRANCH} || exit 1

  fi

fi

