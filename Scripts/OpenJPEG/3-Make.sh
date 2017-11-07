#!/bin/sh

# This script uses the xcodebuild command to build VTK through the CMake-generated xcodeproj. Only specific parts of VTK are built: vtkImagingGeneral and vtkIOImage (and their dependencies)

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir/bin"

export CC=clang
export CXX=clang

if [ ! -f "$libs_dir/libopenjpg.a" ] || [ -f "$cmake_dir/.incomplete" ]; then
    touch "$cmake_dir/.incomplete"

    args=( -j 8 )

    cd "$cmake_dir"
    make "${args[@]}"
    make install

    rm -f "$cmake_dir/.incomplete"
fi

exit 0
