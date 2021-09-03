#!/bin/bash

set -exo pipefail

BUILD_DIRECTORY=`pwd -P`
echo "Build directory: $BUILD_DIRECTORY"

cd `dirname "$0"`
SOURCE_DIRECTORY=`pwd -P`
cd "$BUILD_DIRECTORY"
echo "Source directory: $SOURCE_DIRECTORY"

if [[ ! -f .qmake.super ]]; then
  echo "need to create an empty file ${BUILD_DIRECTORY}/.qmake.super. This appears"
  echo "to be a long-standing bug. This should be checked periodically to see if it is fixed."
  if ! touch .qmake.super; then
    echo "Failed to touch the file. Build exiting."
    exit -1
  fi
fi

"$SOURCE_DIRECTORY/configure" -debug-and-release  -appstore-compliant -force-debug-info -developer-build -opensource -confirm-license -xplatform macx-ios-clang -no-openssl -nomake examples -nomake tests -no-compile-examples -no-widgets -no-icu -no-feature-bearermanagement -securetransport -sdk iphoneos
echo "Configuration complete."

make -j16
echo "Make complete."
