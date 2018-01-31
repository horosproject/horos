#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir"
install_dir="$TARGET_TEMP_DIR/Install"

[ -f "$libs_dir/libCharLS.a" ] && [ ! -f "$cmake_dir/.incomplete" ] && exit 0

export CC=clang
export CXX=clang

touch "$cmake_dir/.incomplete"

args=( -j 8 )

cd "$cmake_dir"
make "${args[@]}"
make install

rm -f "$cmake_dir/.incomplete"

exit 0
