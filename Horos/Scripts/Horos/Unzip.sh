#!/bin/sh

cd "$SRCROOT/Binaries"
unzip -uo DCMTK.zip
unzip -uo DB_Previous_Models.zip
unzip -uo PAGES.zip
unzip -uo OsiriXReport.template.zip
unzip -uo FeedbackReporter.framework.zip
unzip -uo Growl.framework.zip
unzip -uo 3DconnexionClient.framework.zip
unzip -uo dciodvfy.zip
unzip -uo Ming.zip
unzip -uo homephone.framework.zip

unzip -uo weasis-portable*.zip -d weasis
chmod -R 755 weasis
find "$SRCROOT/Binaries/weasis" -name __MACOSX | xargs rm -Rf

cd "$SRCROOT/Binaries/EmbeddedPlugins"
#unzip -uo HorosCloud.horosplugin.zip

cd "$SRCROOT/Binaries/odt2pdf/build"
unzip -uo odt2pdf.zip

cd "$SRCROOT/Binaries/PAGES"
rm ._*

cd "$SRCROOT/DICOMPrint"
unzip -uo libdcmprintscu.dylib.zip
unzip -uo libxerces-c.27.dylib.zip
unzip -uo xercesc.zip

exit 0
