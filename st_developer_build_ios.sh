#!/bin/bash

declare -i no_make=0

if [[ -n "$1" ]]; then
  no_make=1
fi

set -exo pipefail

BUILD_DIRECTORY=`pwd -P`
echo "Build directory: $BUILD_DIRECTORY"

cd `dirname "$0"`
SOURCE_DIRECTORY=`pwd -P`
cd "$BUILD_DIRECTORY"
echo "Source directory: $SOURCE_DIRECTORY"

./st_fix_super.sh

declare -r warnings_off=(
  -Wno-unused-variable
  -Wno-deprecated-declarations
  -Wno-null-pointer-subtraction
)

"$SOURCE_DIRECTORY/configure" -debug-and-release QMAKE_CXXFLAGS_WARN_ON="-Wall ${warnings_off[*]}" QMAKE_IOS_DEPLOYMENT_TARGET=15.0 -appstore-compliant -force-debug-info -developer-build -opensource -confirm-license -xplatform macx-ios-clang -no-openssl -nomake examples -nomake tests -no-compile-examples -no-widgets -no-icu -no-feature-bearermanagement -securetransport -sdk iphoneos
echo "Configuration complete."

if (( no_make == 0 )); then
  make -j 16
  echo "Make complete."
fi
