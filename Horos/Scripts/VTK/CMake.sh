#!/bin/sh

export PATH="$PATH:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin/"

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"
# Backport of https://github.com/eigenteam/eigen-git-mirror/commit/a1292395d
eigen_patch="$(dirname "$path")/Eigen-3.3.4-Clang-21.patch"
cd "$TARGET_NAME"; pwd

env=$(env|sort|grep -v 'LLBUILD_BUILD_ID=\|LLBUILD_LANE_ID=\|LLBUILD_TASK_ID=\|Apple_PubSub_Socket_Render=\|DISPLAY=\|SHLVL=\|SSH_AUTH_SOCK=\|SECURITYSESSIONID=')
hash="$(git describe --always --tags --dirty) $(md5 -q "$path")-$(md5 -q "$eigen_patch")-$(md5 -qs "$env")"

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e Makefile -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

if [ -e ".cmakeenv" ]; then
echo "Rebuilding.."
cat '.cmakeenv'
echo "$env"
fi


command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }
command -v git-lfs >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires git-lfs. Please install git-lfs. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir"; cd "$cmake_dir"

eigen_compat_dir="$cmake_dir/compat-eigen"
mkdir -p "$eigen_compat_dir"
ditto "$PROJECT_DIR/$TARGET_NAME/ThirdParty/eigen/vtkeigen/eigen" "$eigen_compat_dir/Eigen"
/usr/bin/patch --silent -d "$eigen_compat_dir" -p0 < "$eigen_patch"

args=("$PROJECT_DIR/$TARGET_NAME") # -G Xcode
cfs=( -w -fvisibility=default )
cxxfs=( -w -fvisibility=default )

# VTK 8.2 vendors a libpng that selects the removed Carbon <fp.h> header
# once modern Apple Clang predefines TARGET_OS_MAC.  Pre-including its replacement makes
# the legacy guard take the supported <math.h> path without modifying VTK.
cfs+=( -include math.h )
args+=(-DVTK_USE_SYSTEM_EIGEN=ON)
args+=(-DEIGEN3_INCLUDE_DIR="$eigen_compat_dir")
args+=(-DVTK_USE_X:BOOL=OFF)
args+=(-DVTK_USE_COCOA:BOOL=ON)
#args+=(-DVTK_USE_64BITS_IDS=ON) 
args+=(-DBUILD_DOCUMENTATION=OFF)
args+=(-DBUILD_EXAMPLES=OFF)
args+=(-DBUILD_SHARED_LIBS=OFF)
args+=(-DBUILD_TESTING=OFF)
args+=(-DCMAKE_POLICY_VERSION_MINIMUM=3.5)
args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")

args+=(-DVTK_USE_SYSTEM_ZLIB:BOOL=ON)
args+=(-DVTK_USE_SYSTEM_EXPAT=ON)
args+=(-DVTK_USE_SYSTEM_LIBXML2=ON)

# args+=(-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON)

[ "$CONFIGURATION" == 'Release' ] && args+=( -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE=-O3 )

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

args+=(-DCMAKE_IGNORE_PATH="/opt/local/include;/opt/local/lib")

if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
#    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="$CLANG_CXX_LIBRARY")
    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
fi
if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
#    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="$CLANG_CXX_LANGUAGE_STANDARD")
    cxxstd="$CLANG_CXX_LANGUAGE_STANDARD"
    if [ "$cxxstd" = "c++0x" ]; then
        cxxstd="c++11"
    fi
    cxxfs+=(-std="$cxxstd")
fi

# Remove any lingering -std=c++0x from toolchain defaults
for i in "${!cxxfs[@]}"; do
    if [ "${cxxfs[$i]}" = "-std=c++0x" ]; then
        unset 'cxxfs[$i]'
    fi
done
cxxfs+=( -std=c++11 )

if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
fi
if [ ${#cfs[@]} -ne 0 ]; then
    cfss="${cfs[@]}"
    args+=(-DCMAKE_C_FLAGS="$cfss")
fi

# Force a modern C++ standard for VTK/eigen compatibility
args+=(-DCMAKE_CXX_STANDARD=11)
args+=(-DCMAKE_CXX_STANDARD_REQUIRED=ON)

cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.cmakehash"
echo "$env" > "$cmake_dir/.cmakeenv"

exit 0
