#!/bin/bash

printurl() {
  if test -z "$1"; then
    while read -r IN; do
      printurl "${IN}"
    done
  else
    echo "$1" | sed 's|://[^:]*:[^@]*@|://<redacted>@|'
  fi
}

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
echo "   PUSH_TO_GIT_REMOTE [$(printurl ${PUSH_TO_GIT_REMOTE})]"
echo "      Git remote name or URL to push debian tag and"
echo "      changes to, if PUBLISH_TO_REPOSITORY=test."
echo "      Defaults to the remotes containing HEAD ref."
echo "   DRY_RUN [${DRY_RUN}]"
echo "      Set to non-empty string to avoid publishing any"
echo "      package and pushing any change/tag to remote."
echo "----------------------------------------------------"
echo


SRCDIR=${1-"/pkg"}
cd ${SRCDIR} || {
  echo "Did you forget to mount package source to ${SRCDIR} ?" >&2
  exit 1
}

DRY_RUN=${DRY_RUN:-}

GIT_DRY_RUN=
if test -n "${DRY_RUN}"; then
  GIT_DRY_RUN=--dry-run
fi

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

  echo "--------------------------------------------------"
  echo "Giving ownership of all files to ${REPO_OWNER}"
  echo "--------------------------------------------------"
  chown -R ${REPO_OWNER} .
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

START_HASH=$( git rev-parse HEAD )
echo "Start hash (rev-parse HEAD): ${START_HASH}"

REPO_OWNER=$('ls' -ld .git | awk '{print $3}')
echo "Repository owner: ${REPO_OWNER}"

echo "------------------------------"
echo "Updating Debian changelog"
echo "------------------------------"

LAST_COMMITTER_NAME=$(git --no-pager show -s --format='%cn' HEAD)
LAST_COMMITTER_EMAIL=$(git --no-pager show -s --format='%ce' HEAD)

export DEBFULLNAME="${LAST_COMMITTER_NAME}"
export DEBEMAIL="${LAST_COMMITTER_EMAIL}"

git config --global user.email "${LAST_COMMITTER_EMAIL}"
git config --global user.name "${LAST_COMMITTER_NAME}"

msg="New upstream version" #TODO: tweak this (take as param?)
tag=$(git describe --tags --exclude 'debian/*')
dist=$(lsb_release -cs)
version="${tag}-linz~${dist}"

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
  if test -n "${DRY_RUN}"; then
    echo "package_cloud push ${BASE} build-area/*.deb (dry-run)"
  else
    if test -z "${PACKAGECLOUD_TOKEN}"; then
      echo "Cannot publish to packages without a PACKAGECLOUD_TOKEN" >&2
      exit 1;
    fi
    package_cloud push ${BASE} build-area/*.deb || exit 1
  fi

fi

if test -n "${GIT_TAG}"; then

  REMOTES_FILE=.unique-remotes

  :> ${REMOTES_FILE}
  if test -n "${PUSH_TO_GIT_REMOTE}"; then
    echo "${PUSH_TO_GIT_REMOTE}" >> ${REMOTES_FILE}
  fi

  # git for-each-ref will return a format like:
  #
  #   remotes/origin/all-remote-branches
  #   heads/all-remote-branches
  #
  git for-each-ref --contains ${START_HASH} \
      --format='%(refname:lstrip=1)' \
      refs/remotes/ refs/heads/ |
  while read -r REF; do

    if expr "$REF" : heads/ > /dev/null; then

      echo "--------------------------------------------------"
      echo "Head ref containing start hash: ${REF}"
      echo "--------------------------------------------------"

      HEAD=$( echo "${REF}" | sed 's@^heads/@@' )
      echo " Head: ${HEAD}"

      if test "${HEAD}" = "${TMPBRANCH}"; then
        echo " Skipping merge of tag to temp branch's head ${HEAD}"
        continue
      fi

      echo "  Merging tag '${GIT_TAG}' to head '${HEAD}'"
      git checkout "${HEAD}" || exit 1
      git merge --ff-only "${GIT_TAG}" || exit 1
      git checkout - || exit 1

    elif expr "$REF" : remotes/ > /dev/null; then

      echo "--------------------------------------------------"
      echo "Remote ref containing start hash: ${REF}"
      echo "--------------------------------------------------"

      REMOTE_NAME=$( echo "${REF}" | sed 's@^remotes/\([^/]*\)/.*@\1@' )
      echo " Remote name: ${REMOTE_NAME}"

      BRANCH=$(echo "${REF}" | sed "s@^remotes/[^/]*/@@")
      echo " Remote branch: ${BRANCH}"

      if test -z "${REMOTE_NAME}"; then
        continue # something went wrong ?
      fi

      PUSH_TO=${PUSH_TO_GIT_REMOTE:-${REMOTE_NAME}}
      echo " Remote to push to: $(printurl ${PUSH_TO})"

      # Keep note of unique remote names for pushing tag
      grep -qw "${PUSH_TO}" ${REMOTES_FILE} || {
        echo " Saving remote '$(printurl ${PUSH_TO})' to ${REMOTES_FILE}"
        echo "${PUSH_TO}" >> ${REMOTES_FILE}
      }

      if test "${BRANCH}" = "HEAD"; then
        echo " Skipping push to remote's HEAD"
        continue
      fi

      echo "  Pushing debian changes to branch ${BRANCH} of remote $(printurl ${PUSH_TO})"
      git push ${GIT_DRY_RUN} "${PUSH_TO}" ${TMPBRANCH}:${BRANCH} || exit 1


    fi # is a remote ref

  done

  echo "--------------------------------------------------"
  echo "Remotes to push tag to: $(cat ${REMOTES_FILE} | printurl | tr '\n' ' ')"
  echo "--------------------------------------------------"

  while read -r PUSH_TO; do
      test -z "${PUSH_TO}" && continue # skip empty lines
      echo "--------------------------------------------------"
      echo "Pushing tag ${GIT_TAG} to '$(printurl ${PUSH_TO})'"
      echo "--------------------------------------------------"
      echo "git push ${GIT_DRY_RUN} \""$(printurl ${PUSH_TO})"\" ${GIT_TAG}:${GIT_TAG}"
      git push ${GIT_DRY_RUN} "${PUSH_TO}" ${GIT_TAG}:${GIT_TAG} || exit 1
  done < ${REMOTES_FILE}

fi

