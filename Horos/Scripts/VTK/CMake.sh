#!/bin/sh

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"
cd "$TARGET_NAME"; pwd
hash="$(find . \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$path")-$(md5 -qs "$(env | sort)")"

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e Makefile -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir"; cd "$cmake_dir"

args=("$PROJECT_DIR/$TARGET_NAME") # -G Xcode
cxxfs=( -w -fvisibility=default )
args+=(-DVTK_USE_OFFSCREEN_EGL:BOOL=OFF)
args+=(-DVTK_USE_X:BOOL=OFF)
args+=(-DVTK_USE_COCOA:BOOL=ON)
#args+=(-DVTK_USE_64BITS_IDS=ON) 
args+=(-DBUILD_DOCUMENTATION=OFF)
args+=(-DBUILD_EXAMPLES=OFF)
args+=(-DBUILD_SHARED_LIBS=OFF)
args+=(-DBUILD_TESTING=OFF)
args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")

[ "$CONFIGURATION" == 'Release' ] && args+=(-DCMAKE_BUILD_TYPE=RELEASE)

args+=(-DVTK_Group_StandAlone=OFF -DVTK_Group_Rendering=OFF) # disable the default groups
args+=(-DModule_vtkIOImage=ON)
args+=(-DModule_vtkFiltersGeneral=ON)
args+=(-DModule_vtkImagingMorphological=ON)
args+=(-DModule_vtkImagingStencil=ON)
args+=(-DModule_vtkRenderingOpenGL2=ON)
args+=(-DModule_vtkRenderingVolumeOpenGL2=ON)
args+=(-DModule_vtkRenderingAnnotation=ON)
args+=(-DModule_vtkInteractionWidgets=ON)
args+=(-DModule_vtkIOGeometry=ON)
args+=(-DModule_vtkIOExport=ON)
args+=(-DModule_vtkFiltersTexture=ON)
args+=(-DModule_vtktiff=ON)

args+=(-DCMAKE_INSTALL_PREFIX="$install_dir")
args+=(-DVTK_INSTALL_INCLUDE_DIR="include")

if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
#    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="$CLANG_CXX_LIBRARY")
    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
fi
if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
#    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="$CLANG_CXX_LANGUAGE_STANDARD")
    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
fi

if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
fi

cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.cmakehash"

exit 0
