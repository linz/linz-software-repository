#!/bin/bash

echo "----------------------------------"
echo "LINZ Software Packaging system"
echo 
echo "Arguments: $@"
echo
echo "Supported Arguments:"
echo "   <srcdir> dir containing source"
echo "----------------------------------"
echo


SRCDIR=${1-"/pkg"}
cd ${SRCDIR} || {
  echo "Did you forget to mount package source to ${SRCDIR} ?" >&2
  exit 1
}

echo "------------------------------"
echo "Running deb-build-dependencies"
echo "------------------------------"
deb-build-dependencies || exit 1

echo "------------------------------"
echo "Running deb-build-binary"
echo "------------------------------"
deb-build-binary || exit 1

echo "-------------------------------------"
echo "Packages should now be in build-area/"
echo "-------------------------------------"

