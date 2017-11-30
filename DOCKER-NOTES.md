## BUILD CONTAINER
```
$ docker build -t deb-builder:14.04 .
$ docker run \
  -it \
  -v $(pwd):/pkg \
  deb-builder:14.04
```

## IN CONTAINER:
* if LINZ private repo needed
```
$ echo "deb https://<USERNAME>:<PASSWORD>@private-ppa.launchpad.net/linz/test/ubuntu $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/linz.list
```

```
$ cd /pkg
$ deb-build-dependencies
$ deb-build-binary | deb-build-source
```

## OUT OF CONTAINER:
```
$ sudo chown -rv $(id -u):$(id -u) build-area
$ cd build-area
$ debsign <PACKAGE>.changes
```

## TODO
* implement lintian
