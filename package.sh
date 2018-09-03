#!/usr/bin/env bash

set -ex

git clone https://github.com/cloudfoundry-incubator/stratos.git stratos-ui \
    || true

if [ "x$TRAVIS_TAG" != "x" ]; then
	cd stratos-ui
	git checkout $TRAVIS_TAG
	cd ..
fi

function exit_trap() {
    rm -rf /tmp/nodejs.tar.gz /tmp/node6.11.3 # See: install_nodejs.sh
    rm -rf /tmp/glide # See: install_glide.sh
}
trap exit_trap EXIT

if ! which npm > /dev/null; then
    source ./install_nodejs.sh
    export PATH=$NODE_HOME/bin:$PATH
else
    npm_lcation=$(which npm)
    export NODE_HOME=${npm_lcation%%/bin/npm}
fi

if ! which glide > /dev/null; then
    source ./install_glide.sh
    export PATH=$GlideDir:$PATH
fi

mkdir -p cache
CWD="$(pwd)"
BUILD_DIR="$CWD/stratos-ui"

# Add multi-endpoints plugin
#cp -Rp components/register-multi-endpoints ${BUILD_DIR}/components/
#if [ ! -f ${BUILD_DIR}/plugins.orig.json ]; then
#    cp ${BUILD_DIR}/plugins.json ${BUILD_DIR}/plugins.orig.json
#fi
#python append-to-enabled-plugin.py ${BUILD_DIR}/plugins.orig.json "register-multi-endpoints" \
#    | python -m json.tool \
#    > ${BUILD_DIR}/plugins.json

# Patch the build system
patch -Ns -d $BUILD_DIR -p1 < build-fixes.patch \
    || true

bash -x stratos-ui/deploy/cloud-foundry/build.sh "$BUILD_DIR" "$CWD/cache"

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
