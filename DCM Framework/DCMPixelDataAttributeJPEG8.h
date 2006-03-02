//
//  DCMPixelDataAttributeJPEG8.h
//  OsiriX
//
//  Created by Lance Pysher on Mon Aug 02 2004.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Foundation/Foundation.h>
#import "DCMPixelDataAttribute.h"

 
@interface DCMPixelDataAttribute (DCMPixelDataAttributeJPEG8)

- (NSMutableData *)convertJPEG8LosslessToHost:(NSData *)jpegData;
- (NSMutableData *)compressJPEG8:(NSMutableData *)data  compressionSyntax:(DCMTransferSyntax *)compressionSyntax quality:(float)quality;


@end
