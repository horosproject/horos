#!/bin/sh

# VTK libraries are merged into a framework, along with the headers

set -e; set -o xtrace

cmake_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"
libs_dir="$cmake_dir/lib/$CONFIGURATION"
framework="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"
hash=$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)
if [ -e "$framework" -a -f .frameworkhash ]; then
    frameworkhash=$(cat ".frameworkhash")
    if [ "$frameworkhash" = "$hash" ]; then
        exit 0
    fi
fi

rm -Rf "$framework"
echo "$hash" > .frameworkhash

mkdir -p "$framework/Versions/A"
cd "$framework/Versions"
ln -s A Current

ls -al .

cd "$libs_dir"
ars=$(ls *.a)
libtool -static -o "$framework/Versions/A/VTK" $ars

cd "$framework"
ln -s Versions/Current/VTK VTK
mkdir -p "Versions/A/Headers" # "Versions/A/Resources"
ln -s Versions/Current/Headers Headers
# ln -s Versions/Current/Resources Resources

cd Headers

find "$PROJECT_DIR/VTK" \
-not \( -path "$PROJECT_DIR/VTK/Utilities" -prune \) \
-not \( -path "$PROJECT_DIR/VTK/Rendering/OpenGL" -prune \) \
-not \( -path "$PROJECT_DIR/VTK/Rendering/VolumeOpenGL" -prune \) \
-not \( -path "$PROJECT_DIR/VTK/Rendering/ContextOpenGL" -prune \) \
\( -name '*.h*' -o -name '*.txx' \) \
-exec cp -an {} . \;

mkdir -p vtkkwiml
find "$PROJECT_DIR/VTK/Utilities/KWIML/vtkkwiml/include" -name '*.h*' -exec cp -an {} vtkkwiml \;

find "$cmake_dir" -name '*.h*' -exec cp -an {} . \;

find . -type f \( -name '*.hmap' -o -name '*.in' -o -name '*.htm*' -o -name '*.md5' -o -name '*.cmakein'  -o -name '*.h-vms' -o -name '*.bak' \) -delete

sed -i '' -e 's/#include <vtkRenderingVolumeModule.h>/#include "vtkRenderingVolumeModule.h"/g' 'vtkGPUVolumeRayCastMapper.h'
sed -i '' -e 's/typedef TIFF_UINT64_T uint64;//g' -e 's/uint64 tiff_diroff;/TIFF_UINT64_T tiff_diroff;/g' 'tiff.h'

exit 0
