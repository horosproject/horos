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
#import "DCMPixelDataAttribute.h"
#import "jasper.h"

jas_image_t *raw_decode(jas_stream_t *in, NSDictionary *info);


@interface DCMPixelDataAttribute (DCMPixelDataAttributeJPEG2000)  

- (NSMutableData *)encodeJPEG2000:(NSMutableData *)data quality:(int)quality;



@end
