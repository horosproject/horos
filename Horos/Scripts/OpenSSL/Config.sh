#!/bin/sh

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"

cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$path")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
[ -e "Makefile" -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ] && exit 0

cd "$cmake_dir"
rsync -a --delete "$source_dir/" .

export CC=clang
export CXX=clang

config_args=( --prefix="$TARGET_TEMP_DIR/Install" --openssldir="$TARGET_TEMP_DIR/Install" )
configure_args=( --prefix="$TARGET_TEMP_DIR/Install" --openssldir="$TARGET_TEMP_DIR/Install" )
#cfs=($OTHER_CFLAGS)
#cxxfs=($OTHER_CPLUSPLUSFLAGS)

#args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
#args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")

if [ "$CONFIGURATION" = 'Debug' ]; then
    config_args+=( -d )
#    args+=('debug-darwin64-x86_64-cc')
#else
#    args+=('darwin64-x86_64-cc')
fi

#if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
#    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
#fi
#
#if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
#    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
#fi

#if [ ${#cfs[@]} -ne 0 ]; then
#    cfss="${cfs[@]}"
#    args+=(-DCMAKE_C_FLAGS="$cfss")
#fi
#if [ ${#cxxfs[@]} -ne 0 ]; then
#    cxxfss="${cxxfs[@]}"
#    args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
#fi

cd "$cmake_dir"
./config "${config_args[@]}"

if [ "$CONFIGURATION" = 'Debug' ]; then
    ./Configure "${configure_args[@]}" darwin64-x86_64-cc
else
    ./Configure "${configure_args[@]}" debug-darwin64-x86_64-cc
fi

echo "$hash" > "$cmake_dir/.cmakehash"

exit 0
