[![Actions Status](https://github.com/linz/linz-software-repository/workflows/CI/badge.svg?branch=master)](https://github.com/linz/linz-software-repository/actions)

# Management of Toitū Te Whenua LINZ's Software Repository

GitHub action to build Ubuntu packages.

## Use

If you want a GitHub workflow to take care of building packages you just need to use this action
after using a checkout action. For example:

```yaml
steps:
  - uses: actions/checkout@v2.4.0
  - uses: linz/linz-software-repository@v5
```

The default action only builds the packages.

If you want to also publish packages to packagecloud you'll need to pass appropriate parameters:

```yaml
steps:
  - uses: actions/checkout@v2.4.0
  - uses: linz/linz-software-repository@v5
    with:
      packagecloud_repository: 'dev'
      packagecloud_token: ${{ secrets.PACKAGECLOUD_TOKEN }}
```

When publishing to the 'test' repository the action will also try to push changes to
debian/changelog file back to the origin, together with a `debian/xxx` tag. In order for the action
to have credentials to push these objects you'll need to set the "origin" url to include the
authentication token. Note that the token must belong to a user who has permissions to push to all
branches containing the initial reference from the checked out repository (which reference is
checked out depends on the action triggering the event). Protected branches can get in your way!

```yaml
steps:
  - uses: actions/checkout@v2.4.0
  - name: Authorize pushing to remote
    run:
      git remote set-url origin https://x-access-token:${{ secrets.GITHUB_TOKEN
      }}@github.com/${GITHUB_REPOSITORY}
  - uses: linz/linz-software-repository@v5
    with:
      packagecloud_repository: 'test'
      packagecloud_token: ${{ secrets.PACKAGECLOUD_TOKEN }}
```
