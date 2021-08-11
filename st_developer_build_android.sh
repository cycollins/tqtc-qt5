#!/bin/bash

set -exo pipefail

if [ ! -d "$QT_BUILD_SWDEV" ]; then
  echo "Please set QT_BUILD_SWDEV to a valid sw-dev directory path; $QT_BUILD_SWDEV does not exist"
  exit 1;
fi

BUILD_DIRECTORY=`pwd -P`
echo "Build directory: $BUILD_DIRECTORY"

cd `dirname "$0"`
SOURCE_DIRECTORY=`pwd -P`
cd "$BUILD_DIRECTORY"
echo "Source directory: $SOURCE_DIRECTORY"

# This can be armeabi-v7a or x86
arch=${1:-armeabi-v7a}
echo "Architecture: $arch"

unamestr=`uname`
os='unknown'
if [[ "$unamestr" == 'Darwin' ]]; then
  os='osx'
  os_define="CMAKE_HOST_APPLE"
elif [[ "$unamestr" == 'Linux' ]]; then
  os='linux'
  os_define="CMAKE_HOST_UNIX"
fi
echo "OS: $os"
if [[ "$os" == 'unknown' ]]; then
  echo "Error: Unsupported OS \"$unamestr\""
  exit 1
fi

if [ $# -lt 2 ]; then
  openssl_version=`cat "$SOURCE_DIRECTORY/st_openssl_version.txt" | tr -d '\r'`
  mkdir -p "$BUILD_DIRECTORY/qtbase/" && cp -f "$SOURCE_DIRECTORY/st_openssl_version.txt" "$BUILD_DIRECTORY/qtbase/"
  arch_define=`echo $arch | tr [a-z] [A-Z] | tr '-' '_'`
  cmake -D ANDROID=1 -D $os_define=1 -D $arch_define=1 -D SW_DEV="$QT_BUILD_SWDEV" -D OPENSSL_VERSION="$openssl_version" -P "$SOURCE_DIRECTORY/st_third_party.cmake"
  SSL_DIRECTORY=~/.bacon/thirdparty/openssl/$openssl_version-$os-android-$arch
else
  cd "$2"
  SSL_DIRECTORY=`pwd -P`
  cd "$BUILD_DIRECTORY"
fi
echo "SSL directory: $SSL_DIRECTORY"

"$SOURCE_DIRECTORY/configure" -debug -force-debug-info -developer-build -opensource -confirm-license -shared -xplatform android-clang -I "$SSL_DIRECTORY/include" -openssl -nomake examples -nomake tests -no-compile-examples -no-widgets -no-icu -no-dbus -no-feature-bearermanagement -android-sdk $ANDROID_SDK_ROOT -android-ndk $ANDROID_NDK_ROOT -android-ndk-host $ANDROID_NDK_HOST -android-arch $arch -android-toolchain-version 4.9 -no-android-style-assets
echo "Configuration complete."

make -j8
echo "Make complete."
