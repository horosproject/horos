#!/bin/sh

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

[ -f "$install_dir/lib/libopenjp2.a" ] && [ ! -f "$cmake_dir/.incomplete" ] && exit 0

export CC=clang
export CXX=clang

touch "$cmake_dir/.incomplete"

args=( -j 8 )

cd "$cmake_dir"
make "${args[@]}"
make install

rsync "$cmake_dir/bin/libopenjp2.a" "$install_dir/lib/" # somehow the lib isn't copied by make-install
rsync "$source_dir/src/bin/common/format_defs.h" "$install_dir/include/OpenJPEG/" # we need this header

rm -f "$cmake_dir/.incomplete"

exit 0
