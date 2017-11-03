#!/bin/sh

# To avoid excess CMake calls (because these take a long time to execute), this script stores the current git description and md5 hash of the repository CMake directory; when available, it compares the stored values to the current values and exits if nothing has changed.

cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$0")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
build_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"

mkdir -p "$build_dir"; cd "$build_dir"

if [ -e "$TARGET_NAME.xcodeproj" -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

export CC=clang
export CXX=clang

if [ ! -e "$build_dir/Makefile" -o ! -f "$build_dir/.buildhash" ] || [ "$(cat "$build_dir/.buildhash")" != "$hash" ]; then
    mv "$build_dir" "$build_dir.tmp"; rm -Rf "$build_dir.tmp"
    mkdir -p "$build_dir";

    args=( "$source_dir" )
    cxxfs=( -w -fvisibility=hidden -fvisibility-inlines-hidden )

    args+=(-DGDCM_DOCUMENTATION=OFF)
    args+=(-DGDCM_BUILD_TESTING=OFF)
    args+=(-DGDCM_BUILD_DOCBOOK_MANPAGES=OFF)

    args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
    args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")
    args+=(-DCMAKE_INSTALL_PREFIX=/usr/local)

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

    if [ ${#cxxfs[@]} -ne 0 ]; then
        cxxfss="${cxxfs[@]}"
        args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
    fi

    cd "$build_dir"
    cmake "${args[@]}"

    echo "$hash" > "$build_dir/.buildhash"
fi

exit 0
