#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

#[ -f "$install_dir/lib/libgdcmCommon.a" ] && [ ! -f "$cmake_dir/.incomplete" ] && exit 0

export CC=clang
export CXX=clang

touch "$cmake_dir/.incomplete"

args=( -j 8 ) # compile using parallel processes

cd "$cmake_dir"
make "${args[@]}" install

rm -f "$cmake_dir/.incomplete"

exit 0
