#!/usr/bin/env bash

set -o errexit -o noclobber -o nounset -o pipefail
shopt -s failglob inherit_errexit

printurl() {
    if test -z "$1"
    then
        while read -r in
        do
            printurl "${in}"
        done
    else
        echo "${1//:\/\/[^:]*:[^@]*@/://<redacted>@}"
    fi
}

redact() {
    if test -z "$1"
    then
        echo -n
    else
        echo "<redacted>"
    fi
}

cat << EOF
----------------------------------------------------
LINZ Software Packaging system

Supported Environment Variables:
   PACKAGECLOUD_REPOSITORY [${PACKAGECLOUD_REPOSITORY}]
      Packagecloud repository to push packages to.
      Can be 'test', 'dev' or empty (default)
      for not publishing them at all.
      Targetting 'test' also creates a debian tag
      and pushes changes to determined git remote
   PACKAGECLOUD_TOKEN [$(redact "${PACKAGECLOUD_TOKEN}")]
      Token to authorize publishing to packagecloud.
      Only needed if PACKAGECLOUD_REPOSITORY is not empty.
   PUSH_TO_GIT_REMOTE [$(printurl "${PUSH_TO_GIT_REMOTE}")]
      Git remote name or URL to push debian tag and
      changes to, if PACKAGECLOUD_REPOSITORY=test.
      Defaults to the remotes pointing at HEAD ref.
   DRY_RUN [${DRY_RUN-}]
      Set to non-empty string to avoid publishing any
      package and pushing any change/tag to remote.
----------------------------------------------------

EOF

cd /pkg

if test -n "${DRY_RUN-}"
then
    git_dry_run=(--dry-run)
fi

PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin:

tmpbranch=pkg-dev-${HOSTNAME}

cleanup() {

    cat << 'EOF'
 ----------------
|  CLEANING UP   |
 ----------------
EOF

    if test -n "${DRY_RUN-}" -a -n "${git_tag-}"
    then
        cat << 'EOF'
--------------------------------------------------
Removing debian tag (dry run)
--------------------------------------------------
EOF
        git tag -d "${git_tag}"
    fi

    cat << 'EOF'
--------------------------------------------------
Checking out previous branch
--------------------------------------------------
EOF

    git checkout -

    cat << 'EOF'
--------------------------------------------------
Removing temporary branch
--------------------------------------------------
EOF

    git branch -D "${tmpbranch}"

    cat << EOF
--------------------------------------------------
Giving ownership of all files to ${repo_owner}
--------------------------------------------------
EOF

    chown -R "${repo_owner}" .
}

cat << 'EOF'
------------------------------
Extract git information
------------------------------
EOF

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

start_hash="$(git rev-parse HEAD)"
echo "Start hash (rev-parse HEAD): ${start_hash}"

repo_owner="$(find .git -maxdepth 0 -printf %u)"
echo "Repository owner: ${repo_owner}"

cat << 'EOF'
------------------------------
Updating Debian changelog
------------------------------
EOF

last_committer_name=$(git --no-pager show -s --format='%cn' HEAD)
last_committer_email=$(git --no-pager show -s --format='%ce' HEAD)

export DEBFULLNAME="${last_committer_name}"
export DEBEMAIL="${last_committer_email}"

git config --global user.email "${last_committer_email}"
git config --global user.name "${last_committer_name}"

msg="New version"                          #TODO: tweak this (take as param?)
last_version_tag="$(git describe --tags --match '[^d]*')"
tag="${last_version_tag#v}"
dist=$(lsb_release -cs)
version="${tag}-linz~${dist}"

cat << EOF
Using version: $version
Hostname: ${HOSTNAME}
EOF

git checkout -b "${tmpbranch}"

trap 'cleanup' 0

dch -D "${dist}" -v "${version}" "$msg"

git commit --no-verify -m "[debian] Changelog update" debian/changelog

git show --pretty=fuller

cat << 'EOF'
-------------------------------------
Cleaning up build-area/
-------------------------------------
EOF

rm -vrf build-area/

cat << 'EOF'
------------------------------
Running deb-build-dependencies
------------------------------
EOF
deb-build-dependencies.bash

cat << 'EOF'
------------------------------
Running deb-build-binary
------------------------------
EOF
if test "${PACKAGECLOUD_REPOSITORY}" = "test" -o \
    "${PACKAGECLOUD_REPOSITORY}" = "private-test"
then
    deb_build_binary_args=(--git-tag)
fi
log_file='log.deb-build-binary.bash'
if [[ -e "$log_file" ]]
then
    rm "$log_file"
fi
deb-build-binary.bash "${deb_build_binary_args[@]}" >"$log_file" ||
    {
        cat "$log_file"
        exit 1
    }
cat "$log_file"

# If tags are created, we'd get a message like this:
#
# gbp:info: Tagging Debian package 1.10.1-1-ga857db0-linz~bionic1 as debian/1.10.1-1-ga857db0-linz_bionic1 in git
#
git_tag=$(
    grep 'Tagging Debian package .* as debian/' "$log_file" |
        sed 's@.* as debian/@debian/@;s@ in git$@@' || [[ $? -eq 1 ]]
)
if test -n "${git_tag}"
then
    echo "GIT TAG ${git_tag} created"
fi

cat << 'EOF'
-------------------------------------
List packages now in build-area/
-------------------------------------
EOF

ls -l build-area/*.deb

#
# Check if we need to publish
#

if test -n "${PACKAGECLOUD_REPOSITORY}"
then

cat << EOF
--------------------------------------------------
Publishing packages to packagecloud ${PACKAGECLOUD_REPOSITORY}
--------------------------------------------------
EOF

    case "${PACKAGECLOUD_REPOSITORY}" in
        dev | test | private-dev | private-test)
            ;;
        *)
            cat << EOF >&2
Invalid packagecloud repository ${PACKAGECLOUD_REPOSITORY}
Valid values are:
 - dev
 - private-dev
 - test
 - private-test
EOF
            exit 1
            ;;
    esac
    base="linz/${PACKAGECLOUD_REPOSITORY}/ubuntu/${dist}"
    if test -n "${DRY_RUN-}"
    then
        echo "package_cloud push ${base} build-area/*.deb (dry-run)"
    else
        if test -z "${PACKAGECLOUD_TOKEN}"
        then
            echo "Cannot publish to packages without a PACKAGECLOUD_TOKEN" >&2
            exit 1
        fi
        package_cloud push "${base}" build-area/*.deb
    fi

fi

#
# Check if we need to merge changes
#

if test -n "${git_tag}"
then

    remotes_file=.unique-remotes

    : >${remotes_file}
    if test -n "${PUSH_TO_GIT_REMOTE}"
    then
        echo "${PUSH_TO_GIT_REMOTE}" >>${remotes_file}
    fi

    # git for-each-ref will return a format like:
    #
    #   remotes/origin/all-remote-branches
    #   heads/all-remote-branches
    #
    git for-each-ref --points-at "${start_hash}" \
        --format='%(refname:lstrip=1)' \
        refs/remotes/ refs/heads/ |
        while read -r ref
        do

            if expr "$ref" : heads/ >/dev/null
            then

                cat << EOF
--------------------------------------------------
Head ref pointing at start hash: ${ref}
--------------------------------------------------
EOF

                head="${ref//^heads\//}"
                echo " Head: ${head}"

                if test "${head}" = "${tmpbranch}"
                then
                    echo " Skipping merge of tag to temp branch's head ${head}"
                    continue
                fi

                echo " Merging temporary branch to head '${head}'"
                echo "git push ${git_dry_run[*]} . '${tmpbranch}':'${head}'"
                git push "${git_dry_run[@]}" . "${tmpbranch}":"${head}"

            elif expr "$ref" : remotes/ >/dev/null
            then

                cat << EOF
--------------------------------------------------
Remote ref pointing at start hash: ${ref}
--------------------------------------------------
EOF

                remote_name="${ref#*/}"
                remote_name="${remote_name%%/*}"
                echo " Remote name: ${remote_name}"

                branch="${ref#*/}"
                branch="${branch#*/}"
                echo " Remote branch: ${branch}"

                if test -z "${remote_name}"
                then
                    continue # something went wrong ?
                fi

                push_to=${PUSH_TO_GIT_REMOTE:-${remote_name}}
                echo " Remote to push to: $(printurl "${push_to}")"

                # Keep note of unique remote names for pushing tag
                grep -qw "${push_to}" "${remotes_file}" || {
                    echo " Saving remote '$(printurl "${push_to}")' to ${remotes_file}"
                    echo "${push_to}" >>${remotes_file}
                }

                if test "${branch}" = "HEAD"
                then
                    echo " Skipping push to remote's HEAD"
                    continue
                fi

                echo "  Pushing debian changes to branch ${branch} of remote $(printurl "${push_to}")"
                git push "${git_dry_run[@]}" "${push_to}" "${tmpbranch}:${branch}"

            fi
            # is a remote ref

        done

    cat << EOF
--------------------------------------------------
Remotes to push tag to: $(printurl <"${remotes_file}" | tr '\n' ' ')
--------------------------------------------------
EOF

    while read -r push_to
    do
        test -z "${push_to}" && continue # skip empty lines
        cat << EOF
--------------------------------------------------
Pushing tag ${git_tag} to '$(printurl "${push_to}")'
--------------------------------------------------
git push ${git_dry_run[*]} "$(printurl "${push_to}")" ${git_tag}:${git_tag}
EOF
        git push "${git_dry_run[@]}" "${push_to}" "${git_tag}:${git_tag}"
    done < "${remotes_file}"

fi
