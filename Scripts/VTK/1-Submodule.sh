#!/bin/sh

set -e; set -o xtrace

if [ ! -f "$TARGET_NAME/CMakeLists.txt" ]; then
    echo "warning: submodule $TARGET_NAME requires init/update, please wait..."
    cd "$TARGET_NAME"
    git submodule update --init --recursive
fi

exit 0
