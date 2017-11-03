#!/bin/sh

# This script uses the xcodebuild command to build VTK through the CMake-generated xcodeproj. Only specific parts of VTK are built: vtkImagingGeneral and vtkIOImage (and their dependencies)

set -e; set -o xtrace

cmake_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"

xcodebuild -project "$cmake_dir/charls.xcodeproj" -target CharLS -configuration "$CONFIGURATION"

exit 0
