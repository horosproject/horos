#!/bin/sh

set -x

framework_path="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/Horos.framework"

# many plugins are hard-linked to the API framework, and its name changed over time

alts=( HorosAPI OsiriXAPI 'OsiriX Headers' )
for alt in "${alts[@]}"; do
    alt_framework_path="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/$alt.framework"
    rm -Rf "$alt_framework_path"
    mkdir -p "$alt_framework_path/Versions/A"
    ln -s "../../../Horos.framework/Horos" "$alt_framework_path/Versions/A/$alt"
    ln -s "Versions/A/$alt" "$alt_framework_path/$alt"
done

exit 0
