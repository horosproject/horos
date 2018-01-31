#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

[ -f "$install_dir/lib/libITKCommon$ITK_LIB_VERSION_SUFFIX.a" ] && [ ! -f "$cmake_dir/.incomplete" ] && exit 0

touch "$cmake_dir/.incomplete"

args=( -j 8 )

cd "$cmake_dir"
make "${args[@]}" ITKIOImageBase ITKStatistics ITKTransform ITKVTK ITKNrrdIO
make install

rm -f "$cmake_dir/.incomplete"

#xcodebuild -project "$cmake_dir/$TARGET_NAME.xcodeproj" \
#-target ITKIOImageBase -target ITKStatistics -target ITKTransform \
#-target ITKVTK -target ITKNrrdIO \
#-configuration "$CONFIGURATION"

exit 0
