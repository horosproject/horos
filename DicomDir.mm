/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "DicomDir.h"
#include "dcddirif.h"
#include "ofstd.h"

@implementation DicomDir

+(void)createDicomDirAtDir:(NSString*)path {
    DicomDirInterface ddir;
//  ddir.enableVerboseMode();
    ddir.disableConsistencyCheck(); // -W
    ddir.disableTransferSyntaxCheck(); // -Nxc
    ddir.enableInventMode(OFTrue); // +I
    
    ddir.enableIconImageMode(); // +X
    ddir.setIconSize(128);
    
    OFList<OFString> fileNames;
    OFStandard::searchDirectoryRecursively("", fileNames, NULL, path.fileSystemRepresentation); // +r +id burnFolder
    
    OFCondition result = ddir.createNewDicomDir(DicomDirInterface::AP_USBandFlash, [[path stringByAppendingPathComponent:[NSString stringWithUTF8String:DEFAULT_DICOMDIR_NAME]] fileSystemRepresentation], DEFAULT_FILESETID); // -Pfl
    if (!result.good())
        [NSException raise:NSGenericException format:@"Couldn't create new DICOMDIR file: %s", result.text()];
        
    ddir.setFilesetDescriptor(NULL, DEFAULT_DESCRIPTOR_CHARSET);
    
    for (OFListIterator(OFString) iter = fileNames.begin(); iter != fileNames.end(); ++iter) {
        result = ddir.addDicomFile((*iter).c_str(), path.fileSystemRepresentation);
        if (result.bad())
            NSLog(@"Warning: couldn't add %s to DICOMDIR: %s", (*iter).c_str(), result.text());
    }
    
    result = ddir.writeDicomDir(EET_ExplicitLength, EGL_withoutGL);
    if (!result.good())
        [NSException raise:NSGenericException format:@"Couldn't write DICOMDIR file: %s", result.text()];
}

@end
