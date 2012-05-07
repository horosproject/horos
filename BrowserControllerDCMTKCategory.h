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

#import <Cocoa/Cocoa.h>
#import "browserController.h"

/** \brief  Category for DCMTK calls from BrowserController */

@interface BrowserController (BrowserControllerDCMTKCategory)
+ (NSString*) compressionString: (NSString*) string;

#ifndef OSIRIX_LIGHT
- (NSData*) getDICOMFile:(NSString*) file inSyntax:(NSString*) syntax quality: (int) quality;
- (BOOL) testFiles: (NSArray*) files __deprecated;
- (BOOL) needToCompressFile: (NSString*) path __deprecated;
- (BOOL) compressDICOMWithJPEG:(NSArray *) paths __deprecated;
- (BOOL) compressDICOMWithJPEG:(NSArray *) paths to:(NSString*) dest __deprecated;
- (BOOL) decompressDICOMList:(NSArray *) files to:(NSString*) dest __deprecated;
#endif
@end
