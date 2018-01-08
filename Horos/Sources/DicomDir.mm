/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "DicomDir.h"
#import "N2Debug.h"
#include "dcddirif.h"
#include "ofstd.h"

#include "ddpiimpl.h"     /* for class DicomDirImageImplementation */


@implementation DicomDir

+(void)createDicomDirAtDir:(NSString*)path {
    
    try {
        @try {
            DicomDirInterface ddir;
        //  ddir.enableVerboseMode();
            ddir.disableConsistencyCheck(); // -W
            ddir.disableTransferSyntaxCheck(); // -Nxc
            ddir.enableInventMode(OFTrue); // +I
            
        //  ddir.enableIconImageMode(); // +X
            ddir.enableOneIconPerSeriesMode(); // OsiriX addition
            ddir.setIconSize(128); // we let DicomDirInterface pick the icon size.. which, depending on the modality, will be either 128 or 64

            DicomDirImageImplementation imagePlugin;
            ddir.addImageSupport(&imagePlugin);
            
            OFList<OFString> fileNames;
            OFStandard::searchDirectoryRecursively("", fileNames, NULL, path.fileSystemRepresentation); // +r +id burnFolder
            
            NSString* dicomdirPath = [path stringByAppendingPathComponent:[NSString stringWithUTF8String:DEFAULT_DICOMDIR_NAME]];
            OFCondition result = ddir.createNewDicomDir(DicomDirInterface::AP_USBandFlash, [dicomdirPath fileSystemRepresentation], DEFAULT_FILESETID); // -Pfl
            if (!result.good())
                [NSException raise:NSGenericException format:@"Couldn't create new DICOMDIR file: %s", result.text()];
                
            ddir.setFilesetDescriptor(NULL, DEFAULT_DESCRIPTOR_CHARSET); // UTF-8 ?
            
            for (OFListIterator(OFString) iter = fileNames.begin(); iter != fileNames.end(); ++iter) {
                result = ddir.addDicomFile((*iter).c_str(), path.fileSystemRepresentation);
                if (result.bad())
                    NSLog(@"Warning: couldn't add %s to DICOMDIR: %s", (*iter).c_str(), result.text());
            }
            
            result = ddir.writeDicomDir(EET_ExplicitLength, EGL_withoutGL);
            if (!result.good())
                [NSException raise:NSGenericException format:@"Couldn't write DICOMDIR file: %s", result.text()];
            
            chmod([dicomdirPath fileSystemRepresentation], 0755);
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
    } catch (std::exception &e) {
        std::cout << e.what() << std::endl;
    }
}

@end
