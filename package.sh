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

NODE_HOME="$(ls -d /home/travis/.nvm/versions/node/* | head -n 1)" stratos-ui/deploy/cloud-foundry/build.sh ./build ./cache

zip -r stratos-ui-packaged ./build/*
