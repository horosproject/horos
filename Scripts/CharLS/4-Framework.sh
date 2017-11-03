#!/bin/sh

# CharLS libraries are merged into a framework, along with the headers

set -e; set -o xtrace

cmake_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"
libs_dir="$cmake_dir/$CONFIGURATION"
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
libtool -static -o "$framework/Versions/A/CharLS" $ars

cd "$framework"
ln -s Versions/Current/CharLS CharLS
mkdir -p "Versions/A/Headers" "Versions/A/Resources"
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/Resources Resources

cd Headers

find "$PROJECT_DIR/CharLS/src" \( -name '*.h*' \) -exec cp -an {} . \;

#find "$cmake_dir" -name '*.h*' -exec cp -an {} . \;

#find . -type f \( -name '*.hmap' -o -name '*.in' -o -name '*.htm*' -o -name '*.md5' -o -name '*.cmakein'  -o -name '*.h-vms' -o -name '*.bak' \) -delete

exit 0
