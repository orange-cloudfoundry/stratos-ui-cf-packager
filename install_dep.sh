#!/bin/bash
set -euo pipefail

# Download dep

DEP_VERSION="0.5.0"
DEP_PLATFORM="linux-amd64"

DOWNLOAD_FOLDER=/tmp
DOWNLOAD_FILE=${DOWNLOAD_FOLDER}/dep${DEP_VERSION}

export DepInstallDir="/tmp/dep/$DEP_VERSION"
mkdir -p $DepInstallDir

# Download the file if we do not have it cached
if [ ! -f $DepInstallDir/dep ]; then
  URL=https://github.com/golang/dep/releases/download/v${DEP_VERSION}/dep-${DEP_PLATFORM}
  echo "-----> Download dep ${DEP_VERSION}"
  curl -s -L --retry 15 --retry-delay 2 $URL -o ${DOWNLOAD_FILE}
else
  echo "-----> dep install package available in cache"
fi

if [ ! -f $DepInstallDir/dep ]; then
  cp ${DOWNLOAD_FILE} $DepInstallDir/dep
  chmod +x $DepInstallDir/dep
fi

if [ ! -f $DepInstallDir/dep ]; then
  echo "       **ERROR** Could not download dep"
  exit 1
fi
