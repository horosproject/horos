#!/bin/sh

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir/lib/$CONFIGURATION"
framework_path="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"

hash="$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)-$(md5 -q "$0")"
[ -d "$framework_path" -a -f "$cmake_dir/.frameworkhash" ] && [ "$(cat "$cmake_dir/.frameworkhash")" == "$hash" ] && exit 0

rm -Rf "$framework_path"

mkdir -p "$framework_path/Versions/A"
cd "$framework_path/Versions"
ln -s A Current

ars=$(find "$libs_dir" -name '*.a' -type f)
libtool -static -o "$framework_path/Versions/A/$PRODUCT_NAME" $ars

cd "$framework_path"
ln -s "Versions/Current/$PRODUCT_NAME" "$PRODUCT_NAME"
mkdir -p "Versions/A/Headers" # "Versions/A/Resources"
ln -s Versions/Current/Headers Headers
#ln -s Versions/Current/Resources Resources

cd Headers

find "$source_dir" \
-not \( -path "$source_dir/Utilities" -prune \) \
-not \( -path "$source_dir/Rendering/OpenGL" -prune \) \
-not \( -path "$source_dir/Rendering/VolumeOpenGL" -prune \) \
-not \( -path "$source_dir/Rendering/ContextOpenGL" -prune \) \
\( -name '*.h*' -o -name '*.txx' \) \
-exec cp -an {} . \;

mkdir -p vtkkwiml
find "$source_dir/Utilities/KWIML/vtkkwiml/include" -name '*.h*' -exec cp -an {} vtkkwiml \;

find "$cmake_dir" -name '*.h*' -exec cp -an {} . \;

find . -type f \( -name '*.hmap' -o -name '*.in' -o -name '*.htm*' -o -name '*.md5' -o -name '*.cmakein'  -o -name '*.h-vms' -o -name '*.bak' \) -delete

sed -i '' -e 's/#include <vtkRenderingVolumeModule.h>/#include "vtkRenderingVolumeModule.h"/g' 'vtkGPUVolumeRayCastMapper.h'
sed -i '' -e 's/typedef TIFF_UINT64_T uint64;//g' -e 's/uint64 tiff_diroff;/TIFF_UINT64_T tiff_diroff;/g' 'tiff.h'

echo "$hash" > "$cmake_dir/.frameworkhash"

exit 0
