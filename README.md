[![Actions Status](https://github.com/linz/linz-software-repository/workflows/CI/badge.svg?branch=master)](https://github.com/linz/linz-software-repository/actions)

# Management of Toitū Te Whenua LINZ's Software Repository

GitHub action to build Ubuntu packages.

## Use

See [`action.yml`](action.yml) for parameter definitions.

Example:

```yaml
- name: Build package
  uses: linz/linz-software-repository@vN
  with:
    release: jammy
    packages: 'cowsay python3'
    packagecloud_repository: dev
    packagecloud_token: ${{ secrets.PACKAGECLOUD_TOKEN }}
```

To build the package without publishing it, just remove the `packagecloud` parameters above.

When publishing to the 'test' repository the action will also try to push changes to
debian/changelog file back to the origin, together with a `debian/xxx` tag. In order for the action
to have credentials to push these objects you'll need to set the "origin" url to include the
authentication token. Note that the token must belong to a user who has permissions to push to all
branches containing the initial reference from the checked out repository (which reference is
checked out depends on the action triggering the event). Protected branches can get in your way!

```yaml
- name: Authorize pushing to remote
  run:
    git remote set-url origin https://x-access-token:${{ secrets.GITHUB_TOKEN
    }}@github.com/${GITHUB_REPOSITORY}
```

## Manual test

1. Build the builder container in this repository:
   `nix-shell --pure --run 'docker build --tag=docker-builder .'`.
1. Build the project:
   `docker run --env=DRY_RUN=1 --env=GITHUB_REPOSITORY=GITHUB_REPOSITORY --env=RUNNER_WORKSPACE=WORKSPACE --volume=/var/run/docker.sock:/var/run/docker.sock docker-builder RELEASE PACKAGES`
   - [`GITHUB_REPOSITORY` is as defined in the docs](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)
   - `WORKSPACE` is the _parent_ directory of the project
   - The rest of the parameters are as shown in the [use example](#use)

## Release procedure

Using the above, how do you actually release? If you want to release a release:

1. Go to the relevant repository.
1. Update local tags using `git fetch --tags`.
1. Check `git tag` for the latest released version.
1. Depending on whether this is a major (X+1.0.0), minor (X.Y+1.0), or patch (X.Y.Z+1) release:
   - If this is a major or minor release, create a `release-X.Y` branch.
   - If this is a patch release, check out the existing `release-X.Y` branch.
1. Add a change log entry to `CHANGELOG.md`.
1. Look for anywhere there is a list of version numbers, such as the Makefile, test files, or
   others. In all those places, add your new version and add an issue to fix it so that the code
   looks up all the relevant versions by their tags.
1. Do your changes on this branch.
1. Push the branch.
1. Create a pull request for the branch.
1. Wait for the pull request to build.
1. Tag the final commit on the branch with `X.Y.Z`, for example, `1.10.2`.
1. `git push origin TAG` with the tag created above.
1. Verify that all the release jobs succeed.
1. Wait for the package to appear in the [test repository](https://packagecloud.io/linz/test).
1. Manually promote the package from the test repository to production.
1. Wait for the pull request to build with the Debian packaging changelog commit and merge it.

Only at this point is it safe to rely on the new version, because dependee repositories rely on the
state of the `master` branch in their pipelines. :'(
