#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"

[ -f "$cmake_dir/libssl.a" ] && [ ! -f "$cmake_dir/.incomplete" ] && exit 0

export CC=clang
export CXX=clang
export COMMAND_MODE=unix2003

touch "$cmake_dir/.incomplete"

args=( -j 8 )

cd "$cmake_dir"
make "${args[@]}"
make install

rm -f "$cmake_dir/.incomplete"

exit 0
