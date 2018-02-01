#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

[ -d "$install_dir" ] && [ ! -f "$install_dir/.incomplete" ] && exit 0

mkdir -p "$install_dir"
touch "$install_dir/.incomplete"

args=()
export MAKEFLAGS='-j 8'

cd "$cmake_dir"
make "${args[@]}" ITKIOImageBase ITKStatistics ITKTransform ITKVTK ITKNrrdIO
make install

# wrap the libs into one
mkdir -p "$install_dir/wlib"
ars=$(find "$install_dir/lib" -name '*.a' -type f)
libtool -static -o "$install_dir/wlib/lib$PRODUCT_NAME.a" $ars

rm -f "$install_dir/.incomplete"

exit 0

#xcodebuild -project "$cmake_dir/$TARGET_NAME.xcodeproj" \
#-target ITKIOImageBase -target ITKStatistics -target ITKTransform \
#-target ITKVTK -target ITKNrrdIO \
#-configuration "$CONFIGURATION"
