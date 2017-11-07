#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir"

export CC=clang
export CXX=clang

if [ ! -f "$libs_dir/libCharLS.a" ]; then
    touch "$cmake_dir/.incomplete"

    args=( -j 8 )

    cd "$cmake_dir"
    make "${args[@]}"
    make install

    rm -f "$cmake_dir/.incomplete"
fi

exit 0
