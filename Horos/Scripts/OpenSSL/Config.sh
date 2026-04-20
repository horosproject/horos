#!/bin/sh

export PATH="$PATH:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin/"

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"
cd "$TARGET_NAME"; pwd

env=$(env|sort|grep -v 'LLBUILD_BUILD_ID=\|LLBUILD_LANE_ID=\|LLBUILD_TASK_ID=\|Apple_PubSub_Socket_Render=\|DISPLAY=\|SHLVL=\|SSH_AUTH_SOCK=\|SECURITYSESSIONID=')
hash="$(git describe --always --tags --dirty) $(md5 -q "$path")-$(md5 -qs "$env")"

set -e; set -o xtrace; set -o pipefail

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/Config"
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


command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }

mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir"

cd "$cmake_dir"
set +e
ditto "$source_dir" . 2>&1 | tee "$cmake_dir/rsync.log"
copy_status=${PIPESTATUS[0]}
set -e
if [ $copy_status -ne 0 ]; then
    echo "OpenSSL copy failed with exit code $copy_status" >&2
    exit $copy_status
fi

export CC=clang
export CXX=clang
export PERL=/usr/bin/perl

configure_args=( --prefix="$TARGET_TEMP_DIR/Install" --openssldir="$TARGET_TEMP_DIR/Install" -w -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET )
#cfs=($OTHER_CFLAGS)
#cxxfs=($OTHER_CPLUSPLUSFLAGS)

#args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
#args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")

# ./Configure performs configuration; ./config is redundant and can fail under xcodebuild.

#cfs+=(-Wno-sometimes-uninitialized)
#cxxfs+=(-Wno-sometimes-uninitialized)

#if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
#    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
#fi
#
#if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
#    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
#fi

#if [ ${#cfs[@]} -ne 0 ]; then
#    cfss="${cfs[@]}"
#    configure_args+=(-DCMAKE_C_FLAGS="$cfss")
#fi
#if [ ${#cxxfs[@]} -ne 0 ]; then
#    cxxfss="${cxxfs[@]}"
#    configure_args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
#fi

cd "$cmake_dir"

# Use a single arch for OpenSSL Configure (ARCHS can be a list)
arch="${ARCHS%% *}"
if [ -z "$arch" ]; then
    arch="$NATIVE_ARCH_ACTUAL"
fi

set +e
if [ "$CONFIGURATION" = 'Debug' ]; then
    ./Configure "${configure_args[@]}" debug-darwin64-$arch-cc no-shared no-engine no-tests 2>&1 | tee "$cmake_dir/configure.log"
    configure_status=${PIPESTATUS[0]}
else
    ./Configure "${configure_args[@]}" darwin64-$arch-cc no-shared no-engine no-tests 2>&1 | tee "$cmake_dir/configure.log"
    configure_status=${PIPESTATUS[0]}
fi
set -e
if [ $configure_status -ne 0 ]; then
    if [ -f "$cmake_dir/Makefile" ]; then
        echo "OpenSSL ./Configure returned exit code $configure_status but Makefile was created, continuing..." >&2
    else
        echo "OpenSSL ./Configure failed with exit code $configure_status" >&2
        exit $configure_status
    fi
fi

echo "$hash" > "$cmake_dir/.cmakehash"
echo "$env" > "$cmake_dir/.cmakeenv"

exit 0
