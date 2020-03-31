#!/bin/sh

cd "$SRCROOT/Binaries"
unzip -uo DB_Previous_Models.zip
unzip -uo PAGES.zip
unzip -uo OsiriXReport.template.zip
unzip -uo FeedbackReporter.framework.zip
unzip -uo 3DconnexionClient.framework.zip
unzip -uo dciodvfy.zip
unzip -uo Ming.zip
unzip -uo homephone.framework.zip

unzip -uo weasis-portable*.zip -d weasis
chmod -R 755 weasis
find "$SRCROOT/Binaries/weasis" -name __MACOSX | xargs rm -Rf
# remove empty macOS app that prevents notarization
rm -Rf "$SRCROOT/Binaries/weasis/viewer-mac.app"

cd "$SRCROOT/Binaries/EmbeddedPlugins"
#unzip -uo HorosCloud.horosplugin.zip

cd "$SRCROOT/Binaries/PAGES"
rm ._*

exit 0
