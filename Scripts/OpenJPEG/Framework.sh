#!/bin/sh

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir"
framework_path="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"

hash="$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)-$(md5 -q "$0")"
[ -d "$framework_path" -a -f "$cmake_dir/.frameworkhash" ] && [ "$(cat "$cmake_dir/.frameworkhash")" == "$hash" ] && exit 0

rm -Rf "$framework_path"

mkdir -p "$framework_path/Versions/A"

cd "$framework_path/Versions"
ln -s A Current

ars=$(find "$libs_dir" -name '*.a' -type f)
libtool -static -o "$framework_path/Versions/A/$PRODUCT_NAME" $ars

cd "$framework_path"
ln -s "Versions/Current/$PRODUCT_NAME" "$PRODUCT_NAME"
mkdir -p "Versions/A/Headers" # "Versions/A/Resources"
ln -s Versions/Current/Headers Headers
# ln -s Versions/Current/Resources Resources

cd Headers

find "$source_dir/src" \( -name '*.h*' -o -name '*.t*' \) -exec sh -c 'p="${0#*$source_dir/Source/}"; cp -an "{}" "$(basename $p)"' {} \;
find "$cmake_dir/src" \( -name '*.h*' -o -name '*.t*' \) -exec sh -c 'p="${0#*$source_dir/Source/}"; cp -an "{}" "$(basename $p)"' {} \;

find . \( -name '*.htm*' -o -name '*.in' -o -name '*.txt' \) -delete

echo "$hash" > "$cmake_dir/.frameworkhash"

exit 0
