#!/bin/sh

set -e; set -o xtrace

cd "$TARGET_NAME"
git submodule update --init --recursive

exit 0
