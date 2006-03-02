//
//  DCMPixelDataAttributeJPEG12.h
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



@interface DCMPixelDataAttribute (DCMPixelDataAttributeJPEG12)  

- (NSData *)convertJPEG12ToHost:(NSData *)jpegData;
- (NSMutableData *)compressJPEG12:(NSMutableData *)data  compressionSyntax:(DCMTransferSyntax *)compressionSyntax  quality:(float)quality;

@end
