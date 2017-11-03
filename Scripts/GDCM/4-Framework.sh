#!/bin/sh

# VTK libraries are merged into a framework, along with the headers

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
build_dir="$PROJECT_DIR/Build/Intermediates/$TARGET_NAME-$CONFIGURATION.cmake"
libs_dir="$build_dir/bin"
framework_path="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$libs_dir"
hash="$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)-$(md5 -q "$0")"

if [ ! -d "$framework_path" -o ! -f "$build_dir/.frameworkhash" ] || [ "$(cat "$build_dir/.frameworkhash")" != "$hash" ]; then
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

    find "$source_dir/Source" \( -name '*.h*' -o -name '*.t*' \) -exec sh -c 'p="${0#*$source_dir/Source/}"; cp -an "{}" "$(basename $p)"' {} \;
    find "$build_dir/Source" -name '*.h*' -exec sh -c 'p="${0#*$source_dir/Source/}"; cp -an "{}" "$(basename $p)"' {} \;

    find . \( -name '*.htm*' -o -name '*.h.in' -o -name '*.txt' \) -delete

    echo "$hash" > "$build_dir/.frameworkhash"
fi

exit 0
