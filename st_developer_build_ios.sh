#!/bin/bash

set -exo pipefail

BUILD_DIRECTORY=`pwd -P`
echo "Build directory: $BUILD_DIRECTORY"

cd `dirname "$0"`
SOURCE_DIRECTORY=`pwd -P`
cd "$BUILD_DIRECTORY"
echo "Source directory: $SOURCE_DIRECTORY"

"$SOURCE_DIRECTORY/configure" -debug -force-debug-info -c++std c++14 -developer-build -opensource -confirm-license -xplatform macx-ios-clang -no-openssl -nomake examples -nomake tests -no-compile-examples -no-widgets -no-icu -no-feature-bearermanagement -securetransport -sdk iphoneos
echo "Configuration complete."

make -j8
echo "Make complete."
