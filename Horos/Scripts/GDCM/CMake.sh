#!/bin/sh

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"

cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$path")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e Makefile -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

export CC=clang
export CXX=clang

if [ -e "$cmake_dir/Makefile" -a -f "$cmake_dir/.buildhash" ] && [ "$(cat "$cmake_dir/.buildhash")" == "$hash" ]; then
    exit 0
fi

command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir";

args=( "$source_dir" )
cfs=( $OTHER_CFLAGS )
cxxfs=( $OTHER_CPLUSPLUSFLAGS )

args+=(-DGDCM_DOCUMENTATION=OFF)
args+=(-DGDCM_BUILD_TESTING=OFF)
args+=(-DGDCM_BUILD_DOCBOOK_MANPAGES=OFF)

args+=(-DGDCM_USE_SYSTEM_OPENJPEG=ON)
export PKG_CONFIG_PATH="$CONFIGURATION_TEMP_DIR/OpenJPEG.build/Install/lib/pkgconfig"

# currently, GDCM 2.8.3 uses CharLS 1.1, using our CharLS 2.0.0 won't compile
#args+=(-DGDCM_USE_SYSTEM_CHARLS=ON)
#cfs+=( -framework CharLS -F"$TARGET_BUILD_DIR" )
#cxxfs+=( -framework CharLS -F"$TARGET_BUILD_DIR" )

args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")

args+=(-DCMAKE_INSTALL_PREFIX="$TARGET_TEMP_DIR/Install")
args+=(-DGDCM_INSTALL_INCLUDE_DIR="include/GDCM")

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
    args+=( -DCMAKE_C_FLAGS="$cfss" )
fi
if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=( -DCMAKE_CXX_FLAGS="$cxxfss" )
fi

cd "$cmake_dir"
cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.buildhash"

exit 0
