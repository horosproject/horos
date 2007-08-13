//
//  DicomFileDCMTKCategory.h
//  OsiriX
//
//  Created by Lance Pysher on 6/27/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "dicomFile.h"

@interface DicomFile (DicomFileDCMTKCategory)

+ (BOOL) isDICOMFileDCMTK:(NSString *) file;
+ (BOOL) isNRRDFile:(NSString *) file;

- (short) getDicomFileDCMTK;
- (short) getNRRDFile;
@end
