#!/usr/bin/env bash

set -ex
if [ "x$TRAVIS_TAG" != "x" ]; then
	echo "this can be build only when creating release"
	exit 0
fi
git clone https://github.com/SUSE/stratos-ui.git
cd stratos-ui
git checkout $TRAVIS_TAG
cd ..

mkdir cache
mkdir build

stratos-ui/deploy/cloud-foundry/build.sh ./build ./cache

zip -r stratos-ui-packaged ./build/*
