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
cxxfs=( -fvisibility=default )
lfs=() # linker flags
args+=(-DITK_USE_64BITS_IDS=ON)
args+=(-DBUILD_DOCUMENTATION=OFF)
args+=(-DBUILD_EXAMPLES=OFF)
args+=(-DBUILD_SHARED_LIBS=OFF)
args+=(-DBUILD_TESTING=OFF)
args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")

args+=(-DITK_BUILD_DEFAULT_MODULES=OFF)
args+=(-DModule_ITKIOImageBase=ON)
args+=(-DModule_ITKStatistics=ON)
args+=(-DModule_ITKTransform=ON)
args+=(-DModule_ITKVTK=ON)
args+=(-DModule_ITKNrrdIO=ON)
args+=(-DModule_ITKRegionGrowing=ON)
args+=(-DModule_ITKCurvatureFlow=ON)
args+=(-DModule_ITKLevelSets=ON)

args+=(-DCMAKE_INSTALL_PREFIX="$install_dir")
args+=(-DITK_INSTALL_INCLUDE_DIR="include")

args+=(-DITK_USE_SYSTEM_GDCM=ON)
args+=(-DGDCM_DIR="$CONFIGURATION_TEMP_DIR/GDCM.build/CMake")
lfs+=(-L"$CONFIGURATION_TEMP_DIR/OpenJPEG.build/Install/lib")

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

if [ ${#lfs[@]} -ne 0 ]; then
    lfss="${lfs[@]}"
    args+=(-DCMAKE_EXE_LINKER_FLAGS="$lfss")
fi

#args+=(-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON)

cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.cmakehash"

exit 0
