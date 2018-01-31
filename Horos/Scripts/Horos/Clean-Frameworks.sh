#!/bin/sh

set -x

framework_path="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/Horos.framework"

# many plugins are hard-linked to the API framework, and its name changed over time

alts=( HorosAPI OsiriXAPI 'OsiriX Headers' HorosDCM)
for alt in "${alts[@]}"; do
    alt_framework_path="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/$alt.framework"
    rm -Rf "$alt_framework_path"
    cp -R "$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/Horos.framework" "$alt_framework_path"
    mv "$alt_framework_path/Versions/A/Horos" "$alt_framework_path/Versions/A/$alt"
    rm "$alt_framework_path/Horos"
    rm "$alt_framework_path/Headers"
    rm -rf "$alt_framework_path/Versions/A/Headers"
    cd "$alt_framework_path"
    ln -s "Versions/A/$alt"
    sed -i '' "s/Horos/$alt/" "Versions/A/Resources/Info.plist"
    sed -i '' "s/org.horosproject.api/org.horosproject.$alt/" "Versions/A/Resources/Info.plist"
done

#exception since this is temporary
cd "$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/OsiriX Headers.framework"
sed -i '' "s/org.horosproject.OsiriX\ Headers/org.horosproject.OsiriXHeaders/" "Versions/A/Resources/Info.plist"

exit 0
