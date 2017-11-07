#!/bin/sh

# This script uses the xcodebuild command to build VTK through the CMake-generated xcodeproj. Only specific parts of VTK are built: vtkImagingGeneral and vtkIOImage (and their dependencies)

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"

xcodebuild -project "$cmake_dir/$TARGET_NAME.xcodeproj" \
-target vtkIOImage -target vtkFiltersGeneral -target vtkImagingStencil \
-target vtkRenderingOpenGL2 -target vtkRenderingVolumeOpenGL2 -target vtkRenderingAnnotation \
-target vtkInteractionWidgets -target vtkIOGeometry -target vtkIOExport -target vtkFiltersTexture \
-configuration "$CONFIGURATION"

exit 0
