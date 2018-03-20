#!/bin/sh

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

[ -d "$install_dir" ] && [ ! -f "$install_dir/.incomplete" ] && exit 0

mkdir -p "$install_dir"
touch "$install_dir/.incomplete"

args=()
export MAKEFLAGS="-j $(sysctl -n hw.ncpu)"
export CC=clang
export CXX=clang

cd "$cmake_dir"
make "${args[@]}"
make install

rsync "$cmake_dir/bin/libopenjp2.a" "$install_dir/lib/" # somehow the lib isn't copied by make-install
rsync "$source_dir/src/bin/common/format_defs.h" "$install_dir/include/OpenJPEG/" # we need this header

rm -f "$install_dir/.incomplete"

exit 0
