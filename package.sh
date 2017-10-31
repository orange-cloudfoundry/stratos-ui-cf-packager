#!/usr/bin/env bash

set -ex

git clone https://github.com/SUSE/stratos-ui.git

# wating next release
#if [ "x$TRAVIS_TAG" != "x" ]; then
#	cd stratos-ui
#	git checkout $TRAVIS_TAG
#	cd ..
#fi

mkdir cache
CWD="$(pwd)"
npm_lcation="$(which npm)"
BUILD_DIR="$CWD/stratos-ui"

# Add multi-endpoints plugin
mv components/register-multi-endpoints ${BUILD_DIR}/components
mv ${BUILD_DIR}/plugins.json ${BUILD_DIR}/plugins.json.bk
sed '2 a"register-multi-endpoints",' ${BUILD_DIR}/plugins.json.bk > ${BUILD_DIR}/plugins.json
rm ${BUILD_DIR}/plugins.json.bk

NODE_HOME="${npm_lcation%%/bin/npm}" stratos-ui/deploy/cloud-foundry/build.sh "$BUILD_DIR" "$CWD/cache"

# Remove the node_modules and bower_components folders - only needed for build
if [ -d "$BUILD_DIR/node_modules" ]; then
  rm -rf $BUILD_DIR/node_modules
fi

if [ -d "$BUILD_DIR/bower_components" ]; then
  rm -rf $BUILD_DIR/bower_components
fi

echo "web: ./deploy/cloud-foundry/start.sh" > $BUILD_DIR/Procfile

ls -lah "$BUILD_DIR"
cd $BUILD_DIR
zip -r "$CWD/stratos-ui-packaged.zip" ./*
cd "$CWD"