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
#import "DCMObject.h"

/** Category of DCMObject for creating DICOM encapsulated PDFs */
@interface   DCMObject (DCMEncapsulatedPDF) 


/** Encapsulates a pdf in a DICOM file */
+ (DCMObject*) encapsulatedPDF:(NSData *)pdf;


@end
