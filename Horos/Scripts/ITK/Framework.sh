#!/bin/sh

set -e; set -o xtrace

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir/lib/$CONFIGURATION"
framework_path="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"

hash="$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)-$(md5 -q "$path")"
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
#ln -s Versions/Current/Resources Resources

cd Headers

find "$source_dir" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -not -path "$source_dir/Modules/Core/Common/include/compilers/\*" -not -path "$source_dir/Modules/ThirdParty/VNL/src/vxl/vcl/compilers/\*" -exec cp -an {} . \;

mkdir -p compilers
find "$source_dir/Modules/Core/Common/include/compilers" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -exec cp -an {} compilers \;
find "$source_dir/Modules/ThirdParty/VNL/src/vxl/vcl/compilers" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -exec cp -an {} compilers \;

find "$cmake_dir" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -exec cp -an {} . \;

find . -type f -exec sed -i '' \
-e 's/#\(.*\)include <vcl_\(.*\)>/#\1include "vcl_\2"/g' \
-e 's/#\(.*\)include <vnl\/\(.*\)>/#\1include "\2"/g' \
-e 's/#\(.*\)include "vnl\/\(.*\)"/#\1include "\2"/g' \
-e 's/#\(.*\)include <vxl_\(.*\)>/#\1include "vxl_\2"/g' \
-e 's/#\(.*\)include "algo\/vnl_\(.*\)"/#\1include "vnl_\2"/g' \
-e 's/#\(.*\)include "itksys\/\(.*\)"/#\1include "\2"/g' \
-e 's/#\(.*\)include <itksys\/\(.*\)>/#\1include "\2"/g' {} \;

echo "$hash" > "$cmake_dir/.frameworkhash"

exit 0
