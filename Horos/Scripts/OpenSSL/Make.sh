#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/Config"
install_dir="$TARGET_TEMP_DIR/Install"

[ -d "$install_dir" ] && [ ! -f "$install_dir/.incomplete" ] && exit 0

mkdir -p "$install_dir"
touch "$install_dir/.incomplete"

args=()
export MAKEFLAGS="-j $(sysctl -n hw.ncpu)"
export CC=clang
export CXX=clang
export COMMAND_MODE=unix2003

cd "$cmake_dir"
make "${args[@]}"
make install_sw

rm -f "$install_dir/.incomplete"

exit 0
