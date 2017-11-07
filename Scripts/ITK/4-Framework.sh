#!/bin/sh

# ITK libraries are merged into a framework, along with the headers

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
libs_dir="$cmake_dir/lib/$CONFIGURATION"
framework="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"
hash=$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)
if [ -e "$framework" -a -f .frameworkhash ]; then
    frameworkhash=$(cat ".frameworkhash")
    if [ "$frameworkhash" = "$hash" ]; then
        exit 0
    fi
fi

rm -Rf "$framework"
echo "$hash" > .frameworkhash

mkdir -p "$framework/Versions/A"
cd "$framework/Versions"
ln -s A Current

ls -al .

cd "$libs_dir"
ars=$(ls *.a)
libtool -static -o "$framework/Versions/A/ITK" $ars

cd "$framework"
ln -s Versions/Current/ITK ITK
mkdir -p "Versions/A/Headers" "Versions/A/Resources"
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/Resources Resources

cd Headers

find "$PROJECT_DIR/ITK" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -not -path "$PROJECT_DIR/ITK/Modules/Core/Common/include/compilers/\*" -not -path "$PROJECT_DIR/ITK/Modules/ThirdParty/VNL/src/vxl/vcl/compilers/\*" -exec cp -an {} . \;

mkdir -p compilers
find "$PROJECT_DIR/ITK/Modules/Core/Common/include/compilers" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -exec cp -an {} compilers \;
find "$PROJECT_DIR/ITK/Modules/ThirdParty/VNL/src/vxl/vcl/compilers" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -exec cp -an {} compilers \;

find "$cmake_dir" \( -name '*.h' -o -name '*.hxx' -o -name '*.hpp' \) -exec cp -an {} . \;

find . -type f -exec sed -i '' \
-e 's/#\(.*\)include <vcl_\(.*\)>/#\1include "vcl_\2"/g' \
-e 's/#\(.*\)include <vnl\/\(.*\)>/#\1include "\2"/g' \
-e 's/#\(.*\)include "vnl\/\(.*\)"/#\1include "\2"/g' \
-e 's/#\(.*\)include <vxl_\(.*\)>/#\1include "vxl_\2"/g' \
-e 's/#\(.*\)include "algo\/vnl_\(.*\)"/#\1include "vnl_\2"/g' \
-e 's/#\(.*\)include "itksys\/\(.*\)"/#\1include "\2"/g' \
-e 's/#\(.*\)include <itksys\/\(.*\)>/#\1include "\2"/g' {} \;

exit 0
