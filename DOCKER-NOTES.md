## BUILD CONTAINER
```
$ docker build -t deb-builder .
$ docker run -v $(pwd):/pkg -it --entrypoint /bin/bash deb-builder
```

## IN CONTAINER:
```
$ echo "deb http://apt.postgresql.org/pub/repos/apt/ $DIST-pgdg main" \
> /etc/apt/sources.list.d/pgdg.list

$ echo "deb https://<USERNAME>:<PASSWORD>@private-ppa.launchpad.net/linz/test/ubuntu $DIST main" \
> /etc/apt/sources.list.d/linz.list
```
```
$ cd /pkg
$ DEBIAN_FRONTEND=noninteractive mk-build-deps -i -r -t 'apt-get -y' debian/control
$ gbp buildpackage --git-export-dir=build-area --git-ignore-branch --git-ignore-new --git-builder=debuild --git-no-pristine-tar --git-upstream-tag='%(version)s' -i.git -I.git -uc -us -b
```

## OUT OF CONTAINER:
```
$ cd build-area
$ sudo chown -v $(id -u):$(id -u) *.*
$ debsign <PACKAGE>.changes
```
