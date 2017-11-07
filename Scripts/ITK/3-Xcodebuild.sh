#!/bin/sh

# This script uses the xcodebuild command to build ITK through the CMake-generated xcodeproj. Only specific parts of ITK are built.

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"

xcodebuild -project "$cmake_dir/$TARGET_NAME.xcodeproj" \
-target ITKIOImageBase -target ITKStatistics -target ITKTransform \
-target ITKVTK -target ITKNrrdIO \
-configuration "$CONFIGURATION"

exit 0
