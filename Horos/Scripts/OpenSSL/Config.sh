#!/bin/sh

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"

cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$path")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/Config"
install_dir="$TARGET_TEMP_DIR/Install"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
[ -e "Makefile" -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ] && exit 0

command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir"

cd "$cmake_dir"
rsync -a --delete "$source_dir/" .

export CC=clang
export CXX=clang

config_args=( --prefix="$TARGET_TEMP_DIR/Install" --openssldir="$TARGET_TEMP_DIR/Install" -w )
configure_args=( --prefix="$TARGET_TEMP_DIR/Install" --openssldir="$TARGET_TEMP_DIR/Install" -w )
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

#cfs+=(-Wno-sometimes-uninitialized)
#cxxfs+=(-Wno-sometimes-uninitialized)

#if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
#    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
#fi
#
#if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
#    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
#fi

#if [ ${#cfs[@]} -ne 0 ]; then
#    cfss="${cfs[@]}"
#    configure_args+=(-DCMAKE_C_FLAGS="$cfss")
#fi
#if [ ${#cxxfs[@]} -ne 0 ]; then
#    cxxfss="${cxxfs[@]}"
#    configure_args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
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
