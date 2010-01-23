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
#import "DicomImage.h"

/** \brief  DCMTK calls for Dicom Image */ 
@interface DicomImage (DicomImageDCMTKCategory)

- (NSString *)keyObjectType;
- (NSArray *)referencedObjects;
@end
