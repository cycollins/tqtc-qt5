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

bits=$1
if [[ -z "$bits" ]]; then
  if [[ "$(uname -m)" == "x86_64" ]]; then
    bits="64"
  else
    bits="32"
  fi
  echo "Bits: $bits (from build machine)"
else
  echo "Bits: $bits (user specified)"
fi

arch=$2
if [[ -z "$arch" ]]; then
  arch=$(uname -m)
  echo "Architecture: $arch (from build machine)"
else
  echo "Architecture: $arch (user specified)"
fi

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

check_call "$SOURCE_DIRECTORY/configure" -prefix "$BUILD_DIRECTORY/$version" -release -force-debug-info -opensource -confirm-license -shared -platform linux-g++-$bits -nomake examples -nomake tests -no-compile-examples -xinput2 -opengl -fontconfig -qt-xcb -qt-libjpeg -qt-harfbuzz -no-icu -no-feature-bearermanagement -no-dbus
echo "Configuration complete."

check_call make -j8
echo "Make complete."

check_call python "$SOURCE_DIRECTORY/st_gen_and_upload_symbols.py" --os linux --swdev "$SW_DEV"
echo "Symbol upload complete."

check_call make install
echo "Installation to staging directory complete."

find ./$version -name '*.a' -or -name '*.so' -print0 | xargs -0 strip
echo "Libraries in staging directory stripped."

check_call tar cvzf qt-$version-linux-$arch.tar.gz ./$version
echo "Tarball generation complete."

# Delete the version folder, since the way teamcity cleans things having a folder that's
# also a revision is bad
rm -rf ./$version
echo "Staging directory deletion complete."
