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

NODE_HOME="/home/travis/.nvm/versions/node/v7.4.0/bin" stratos-ui/deploy/cloud-foundry/build.sh ./build ./cache

zip -r stratos-ui-packaged ./build/*
