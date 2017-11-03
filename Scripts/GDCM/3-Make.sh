#!/bin/sh

# This script uses the xcodebuild command to build VTK through the CMake-generated xcodeproj. Only specific parts of VTK are built: vtkImagingGeneral and vtkIOImage (and their dependencies)

set -e; set -o xtrace

build_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"
libs_dir="$build_dir/bin"

export CC=clang
export CXX=clang

if [ ! -f "$libs_dir/libgdcmCommon.a" ] || [ -f "$build_dir/.incomplete" ]; then
    touch "$build_dir/.incomplete"

    args=( -j 8 )

    cd "$build_dir"
    make "${args[@]}"

    rm -f "$build_dir/.incomplete"
fi

exit 0
