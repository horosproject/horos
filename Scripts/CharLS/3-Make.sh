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

#mkdir -p "$install_dir/pkgconfig"
#
#[ ! -f "$install_dir/pkgconfig/CharLS.pc" ] && cat > "$install_dir/pkgconfig/CharLS.pc" <<EOF
#prefix=$install_dir
#bindir=\${prefix}/
#mandir=\${prefix}/
#docdir=\${prefix}/
#libdir=\${prefix}/lib
#includedir=\${prefix}/include
#
#Name: CharLS
#Description: CharLS
#Version: 2.0.0
#Libs: -L\${libdir} -lCharLS
#Libs.private: -lm
#Cflags: -isystem \${includedir}
#EOF

rm -f "$cmake_dir/.incomplete"

exit 0
