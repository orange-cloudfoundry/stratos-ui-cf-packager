#!/usr/bin/env bash

set -ex

git clone https://github.com/cloudfoundry-incubator/stratos.git stratos-ui \
    || true

if [[ -n $TRAVIS_TAG ]]; then
	pushd stratos-ui
	git checkout "$TRAVIS_TAG"
    export stratos_version="$TRAVIS_TAG"
	popd
fi

function exit_trap() {
    # See: install_nodejs.sh
    NODE_VERSION="8.11.2"
    rm -rf /tmp/node${NODE_VERSION}.tar.gz /tmp/node${NODE_VERSION}
}
trap exit_trap EXIT

if ! which npm > /dev/null; then
    source ./install_nodejs.sh
    export PATH=$NODE_HOME/bin:$PATH
else
    npm_location=$(which npm)
    export NODE_HOME=${npm_location%%/bin/npm}
fi

mkdir -p cache
CWD="$(pwd)"
BUILD_DIR="$CWD/stratos-ui"

# Patch the build system
# THIS BECOMING USELESS CAUSE OF THE REWRITE OF bk-build.sh (inside now build/bk-build.sh)
# patch -Ns -d $BUILD_DIR -p1 < build-fixes.patch || true

# Fix the "authenticity of host can't be established" error in travis build
ssh-keyscan "bitbucket.org" >> ~/.ssh/known_hosts

# prebuild ui
cd stratos-ui
npm install
npm run prebuild-ui
rm -Rf ./dist

# Actually build Stratos
bash -x deploy/cloud-foundry/build.sh "$BUILD_DIR" "$CWD/cache"
cd "$CWD"
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
