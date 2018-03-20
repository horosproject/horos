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

cd "$cmake_dir"
make "${args[@]}" install

# missing tiff headers
mkdir -p "$install_dir/include/vtktiff/libtiff"
find "$source_dir/ThirdParty/tiff/vtktiff/libtiff"  -name '*.h' -exec rsync {} "$install_dir/include/vtktiff/libtiff/" \;
rsync "$cmake_dir/ThirdParty/tiff/vtktiff/libtiff/tiffconf.h" "$install_dir/include/vtktiff/libtiff/"

# missing deprecated vtkVolumeTextureMapper headers # TODO: remove after updating to VTK 8.1
rsync "$source_dir/Rendering/Volume/vtkVolumeTextureMapper.h" "$install_dir/include/"
rsync "$source_dir/Rendering/Volume/vtkVolumeTextureMapper2D.h" "$install_dir/include/"

# wrap the libs into one
mkdir -p "$install_dir/wlib"
ars=$(find "$install_dir/lib" -name '*.a' -type f)
libtool -static -o "$install_dir/wlib/lib$PRODUCT_NAME.a" $ars

rm -f "$install_dir/.incomplete"

exit 0

#xcodebuild -project "$cmake_dir/$TARGET_NAME.xcodeproj" \
#-target vtkIOImage -target vtkFiltersGeneral -target vtkImagingStencil \
#-target vtkRenderingOpenGL2 -target vtkRenderingVolumeOpenGL2 -target vtkRenderingAnnotation \
#-target vtkInteractionWidgets -target vtkvtkVolumeTextureMapper2D.hIOGeometry -target vtkIOExport -target vtkFiltersTexture \
#-configuration "$CONFIGURATION"
