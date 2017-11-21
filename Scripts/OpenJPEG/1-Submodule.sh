#!/bin/sh

set -e; set -o xtrace

[ -f "$TARGET_NAME/CMakeLists.txt" ] && exit 0

cd "$TARGET_NAME"
git submodule update --init --recursive

exit 0
