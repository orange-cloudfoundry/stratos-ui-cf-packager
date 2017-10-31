#!/usr/bin/env bash

set -ex

git clone https://github.com/SUSE/stratos-ui.git

if [ "x$TRAVIS_TAG" != "x" ]; then
	cd stratos-ui
	git checkout $TRAVIS_TAG
	cd ..
fi

mkdir cache
CWD="$(pwd)"
npm_lcation="$(which npm)"
BUILD_DIR="$CWD/stratos-ui"
NODE_HOME="${npm_lcation%%/bin/npm}" stratos-ui/deploy/cloud-foundry/build.sh "$BUILD_DIR" "$CWD/cache"

# Remove the node_modules and bower_components folders - only needed for build
if [ -d "$BUILD_DIR/node_modules" ]; then
  rm -rf $BUILD_DIR/node_modules
fi

if [ -d "$BUILD_DIR/bower_components" ]; then
  rm -rf $BUILD_DIR/bower_components
fi

cd "$CWD"
ls -lah "$BUILD_DIR"
zip -r stratos-ui-packaged ./stratos-ui/*
