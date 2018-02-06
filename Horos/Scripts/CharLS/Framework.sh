#!/bin/sh

set -e; set -o xtrace

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"

cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir"
framework_path="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"

hash="$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)-$(md5 -q "$path")"
[ -d "$framework_path" -a -f "$cmake_dir/.frameworkhash" ] && [ "$(cat "$cmake_dir/.frameworkhash")" == "$hash" ] && exit 0

rm -Rf "$framework_path"

mkdir -p "$framework_path/Versions/A"
cd "$framework_path/Versions"
ln -s A Current

ars=$(find "$libs_dir" -name '*.a' -type f)
libtool -static -o "$framework_path/Versions/A/CharLS" $ars

cd "$framework_path"
ln -s "Versions/Current/$PRODUCT_NAME" "$PRODUCT_NAME"
mkdir -p "Versions/A/Headers" # "Versions/A/Resources"
ln -s Versions/Current/Headers Headers
# ln -s Versions/Current/Resources Resources

cd Headers

find "$PROJECT_DIR/CharLS/src" \( -name '*.h*' \) -exec cp -an {} . \;

#find "$cmake_dir" -name '*.h*' -exec cp -an {} . \;

#find . -type f \( -name '*.hmap' -o -name '*.in' -o -name '*.htm*' -o -name '*.md5' -o -name '*.cmakein'  -o -name '*.h-vms' -o -name '*.bak' \) -delete

echo "$hash" > "$cmake_dir/.frameworkhash"

exit 0
