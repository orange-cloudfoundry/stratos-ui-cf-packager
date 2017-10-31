#!/usr/bin/env bash

set -ex

git clone https://github.com/SUSE/stratos-ui.git

if [ "x$TRAVIS_TAG" != "x" ]; then
	cd stratos-ui
	git checkout $TRAVIS_TAG
	cd ..
fi

mkdir cache
mkdir build
CWD="$(pwd)"
npm_lcation="$(which npm)"
NODE_HOME="${npm_lcation%%/bin/npm}" stratos-ui/deploy/cloud-foundry/build.sh "$CWD/build" "$CWD/cache"

zip -r stratos-ui-packaged ./build/*
