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

/** \brief Converts DICOM string  to NSString */

#import <Cocoa/Cocoa.h>

@interface NSString  (DICOMToNSString)

- (id) initWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding;
+ (id) stringWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding;
+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet;


@end
