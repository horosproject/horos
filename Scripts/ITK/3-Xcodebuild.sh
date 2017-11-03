#!/bin/sh

# This script uses the xcodebuild command to build ITK through the CMake-generated xcodeproj. Only specific parts of ITK are built.

set -e; set -o xtrace

cmake_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"

xcodebuild -project "$cmake_dir/$TARGET_NAME.xcodeproj" \
-target ITKIOImageBase -target ITKStatistics -target ITKTransform \
-target ITKVTK -target ITKNrrdIO \
-configuration "$CONFIGURATION"

exit 0
