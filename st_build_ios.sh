#!/bin/bash

set -exo pipefail

function check_call() {
  if [ -z "$1" ]; then
    echo "Please pass a command to check_call"
    exit 1
  fi

  echo "Running $@"
  $@
  exit_code=$?
  if [ "$exit_code" -ne "0" ]; then
    echo "Command: $1 failed with code $exit_code"
    exit $exit_code
  else
    return $exit_code
  fi
}

BUILD_DIRECTORY=`pwd -P`
echo "Build directory: $BUILD_DIRECTORY"

cd `dirname "$0"`
SOURCE_DIRECTORY=`pwd -P`
cd "$BUILD_DIRECTORY"
echo "Source directory: $SOURCE_DIRECTORY"

cd "$SOURCE_DIRECTORY"
if [ -z "$TEAMCITY_GIT_PATH" ]; then
  TEAMCITY_GIT_PATH=git
fi
version=`"$TEAMCITY_GIT_PATH" rev-parse HEAD`
cd "$BUILD_DIRECTORY"
if [ -z "$version" ]; then
  echo "Error: could not get the revision."
  exit 1;
fi
echo "Revision: $version"

source "$SOURCE_DIRECTORY/st_set_swdev.sh"
echo "SW-DEV: $SW_DEV"

./st_fix_super.sh

check_call "$SOURCE_DIRECTORY/configure" -prefix "$BUILD_DIRECTORY/$version" -debug-and-release  -appstore-compliant -force-debug-info -c++std c++14 -commercial -confirm-license -xplatform macx-ios-clang -nomake examples -nomake tests -no-compile-examples -no-widgets -no-icu -no-feature-bearermanagement -securetransport -sdk iphoneos
echo "Configuration complete."

check_call make -j16
echo "Make complete."

# Static build; don't need symbols until after link
# python "$SOURCE_DIRECTORY/st_gen_and_upload_symbols.py" --os ios --swdev "$SW_DEV"
# echo "Symbol upload complete."

check_call make install
echo "Installation to staging directory complete."

check_call tar cvzf qt-$version-ios.tar.gz ./$version
echo "Tarball generation complete."

# Delete the version folder, since the way teamcity cleans things having a folder that's
# also a revision is bad
rm -rf ./$version
echo "Staging directory deletion complete."
