#!/bin/sh

cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$0")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e "$TARGET_NAME.xcodeproj" -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"; rm -Rf "$cmake_dir.tmp"
mkdir -p "$cmake_dir"

export CC=clang
export CXX=clang

args=("$PROJECT_DIR/$TARGET_NAME")
cfs=($OTHER_CFLAGS)
cxxfs=($OTHER_CPLUSPLUSFLAGS)

args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")
args+=(-DCMAKE_INSTALL_PREFIX="$TARGET_TEMP_DIR/Install")

args+=(-DBUILD_DOC=OFF)
args+=(-DBUILD_EXAMPLES=OFF)
args+=(-DBUILD_SHARED_LIBS=OFF)
args+=(-DBUILD_STATIC_LIBS=ON)
args+=(-DBUILD_TESTING=OFF)

if [ "$CONFIGURATION" = 'Debug' ]; then
    cxxfs+=( -g )
else
    cxxfs+=( -O2 )
fi

if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
fi

if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
fi

if [ ${#cfs[@]} -ne 0 ]; then
    cfss="${cfs[@]}"
    args+=(-DCMAKE_C_FLAGS="$cfss")
fi
if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
fi

cd "$cmake_dir"
cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.cmakehash"

exit 0
