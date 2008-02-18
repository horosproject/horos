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
#import "browserController.h"

/** \brief  Category for DCMTK calls from BrowserController */

@interface BrowserController (BrowserControllerDCMTKCategory)

- (BOOL)compressDICOMWithJPEG:(NSString *)path;
- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest;
- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest deleteOriginal:(BOOL) deleteOriginal;

@end
