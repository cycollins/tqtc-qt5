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

# This can be osx or linux
os=$1
if [[ "$os" == 'osx' ]]; then
  os_define="CMAKE_HOST_APPLE"
elif [[ "$os" == 'linux' ]]; then
  os_define="CMAKE_HOST_UNIX"
else
  echo "Error: Unsupported OS \"$os\""
  exit 1;
fi
echo "OS: $os"

# This can be armeabi-v7a or x86
arch=$2
if [ -z "$arch" ]; then
  echo "Error: no architecture specified."
  exit 1;
fi
echo "Architecture: $arch"

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

openssl_version=`cat "$SOURCE_DIRECTORY/st_openssl_version.txt" | tr -d '\r'`
mkdir -p "$BUILD_DIRECTORY/qtbase/" && cp -f "$SOURCE_DIRECTORY/st_openssl_version.txt" "$BUILD_DIRECTORY/qtbase/"
arch_define=`echo $arch | tr [a-z] [A-Z] | tr '-' '_'`
cmake -D ANDROID=1 -D $os_define=1 -D $arch_define=1 -D SW_DEV="$SW_DEV" -D OPENSSL_VERSION="$openssl_version" -P "$SOURCE_DIRECTORY/st_third_party.cmake"
SSL_DIRECTORY=~/.bacon/thirdparty/openssl/$openssl_version-$os-android-$arch

# Only add symbols on Linux; see below
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  force_debug_info="-force-debug-info"
else
  force_debug_info=
fi

check_call "$SOURCE_DIRECTORY/configure" -prefix "$BUILD_DIRECTORY/$version" -release $force_debug_info -commercial -confirm-license -shared -xplatform android-clang -I "$SSL_DIRECTORY/include" -openssl -nomake examples -nomake tests -no-compile-examples -no-dbus -no-feature-bearermanagement -no-widgets -no-icu -android-sdk $ANDROID_SDK_ROOT -android-ndk $ANDROID_NDK_ROOT -android-ndk-host $ANDROID_NDK_HOST -android-arch $arch -android-toolchain-version 4.9
echo "Configuration complete."

check_call make -j8
echo "Make complete."

# Symbol dumping only works on Linux, which has
# the right elf headers
if [[ "$unamestr" == 'Linux' ]]; then
  check_call python "$SOURCE_DIRECTORY/st_gen_and_upload_symbols.py" --os android --swdev "$SW_DEV"
  echo "Symbol upload complete."
else
  echo "No symbol upload for non-Linux platform: $unamestr"
fi

check_call make install
cp "$BUILD_DIRECTORY/qtbase/st_openssl_version.txt" "$BUILD_DIRECTORY/$version/"
echo "Installation to staging directory complete."

check_call tar cvzf qt-$version-$os-android-$arch.tar.gz ./$version
echo "Tarball generation complete."

# Delete the version folder, since the way teamcity cleans things having a folder that's
# also a revision is bad
rm -rf ./$version
echo "Staging directory deletion complete."
