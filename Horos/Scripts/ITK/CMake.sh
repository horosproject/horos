#!/bin/sh

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"

cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$path")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e "$TARGET_NAME.xcodeproj" -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }

cd ..
mv "$cmake_dir" "$cmake_dir.tmp"; rm -Rf "$cmake_dir.tmp"
mkdir -p "$cmake_dir"; cd "$cmake_dir"

echo "$hash" > .cmakehash

args=("$PROJECT_DIR/$TARGET_NAME" -G Xcode)
cxxfs=( -fvisibility=hidden -fvisibility-inlines-hidden )
args+=(-DITK_USE_64BITS_IDS=ON)
args+=(-DBUILD_DOCUMENTATION=OFF)
args+=(-DBUILD_EXAMPLES=OFF)
args+=(-DBUILD_SHARED_LIBS=OFF)
args+=(-DBUILD_TESTING=OFF)
args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")
args+=(-DCMAKE_INSTALL_PREFIX=/usr/local)
if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="$CLANG_CXX_LIBRARY")
    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
fi
if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="$CLANG_CXX_LANGUAGE_STANDARD")
    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
fi

if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
fi

cmake "${args[@]}"

exit 0
