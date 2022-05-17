#!/bin/bash

set -exo pipefail

BUILD_DIRECTORY=`pwd -P`
echo "Build directory: $BUILD_DIRECTORY"

cd `dirname "$0"`
SOURCE_DIRECTORY=`pwd -P`
cd "$BUILD_DIRECTORY"
echo "Source directory: $SOURCE_DIRECTORY"

./st_fix_super.sh

"$SOURCE_DIRECTORY/configure" -debug-and-release  -appstore-compliant  -c++std c++14 -developer-build -opensource -confirm-license -shared -platform macx-clang -no-openssl -nomake examples -nomake tests -no-compile-examples -no-icu -no-pch -no-feature-bearermanagement -no-framework -securetransport
echo "Configuration complete."

make -j16
echo "Make complete."
