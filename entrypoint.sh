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
echo "Running deb-build-dependencies"
echo "------------------------------"
deb-build-dependencies || exit 1

echo "------------------------------"
echo "Updating Debian changelog"
echo "------------------------------"
msg="New upstream version" #TODO: tweak this (take as param?)
tag=$(git describe --tags --exclude 'debian/*')
pkgser=1 #package serial -- TODO: tweak this (take as param?)
dist=$(lsb_release -cs)
dch -D ${dist} -v \
  "${tag}-${pkgser}linz~${dist}1" \
  $msg \
  || exit 1

echo "------------------------------"
echo "Running deb-build-binary"
echo "------------------------------"
deb-build-binary || exit 1

echo "-------------------------------------"
echo "Packages should now be in build-area/"
echo "-------------------------------------"

