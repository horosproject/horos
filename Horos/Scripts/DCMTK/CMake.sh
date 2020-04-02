#!/bin/sh

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"
cd "$TARGET_NAME"; pwd

env=$(env|sort|grep -v 'LLBUILD_BUILD_ID=\|LLBUILD_LANE_ID=\|LLBUILD_TASK_ID=\|Apple_PubSub_Socket_Render=\|DISPLAY=\|SHLVL=\|SSH_AUTH_SOCK=\|SECURITYSESSIONID=')
hash="$(git describe --always --tags --dirty) $(md5 -q "$path")-$(md5 -qs "$env")"

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e "$cmake_dir/Makefile" -a -f "$cmake_dir/.buildhash" ] && [ "$(cat "$cmake_dir/.buildhash")" == "$hash" ]; then
    exit 0
fi

if [ -e ".cmakeenv" ]; then
    echo "Rebuilding.."
    cat '.cmakeenv'
    echo "$env"
fi

command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir";

args=( "$source_dir" )
cfs=( $OTHER_CFLAGS )
cxxfs=( $OTHER_CPLUSPLUSFLAGS )

args+=(-Wno-dev)
args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")
args+=(-DDCMTK_ENABLE_MANPAGES=OFF)

args+=(-DCMAKE_INSTALL_PREFIX="$install_dir")

export PKG_CONFIG_PATH="$CONFIGURATION_TEMP_DIR/OpenJPEG.build/Install/lib/pkgconfig"

#cxxfs+=( -I/usr/local/opt/openssl/include )

if [ "$CONFIGURATION" = 'Debug' ]; then
    cxxfs+=( -g )
else
    cxxfs+=( -O2 )
fi

if [ ${#cfs[@]} -ne 0 ]; then
    cfss="${cfs[@]}"
    args+=( -DCMAKE_C_FLAGS="$cfss" )
fi
if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=( -DCMAKE_CXX_FLAGS="$cxxfss" )
fi

args+=(-DDCMTK_WITH_OPENSSL=ON)
args+=(-DOPENSSL_CRYPTO_LIBRARY="$CONFIGURATION_TEMP_DIR/OpenSSL.build/Install/lib/libcrypto.a")
args+=(-DOPENSSL_INCLUDE_DIR="$CONFIGURATION_TEMP_DIR/OpenSSL.build/Install/include")
args+=(-DOPENSSL_SSL_LIBRARY="$CONFIGURATION_TEMP_DIR/OpenSSL.build/Install/lib/libssl.a")

cd "$cmake_dir"
cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.buildhash"
echo "$env" > "$cmake_dir/.cmakeenv"

exit 0
