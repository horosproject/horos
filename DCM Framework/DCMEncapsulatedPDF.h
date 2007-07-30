//
//  DCMEncapsulatedPDF.h
//  OsiriX
//
//  Created by Lance Pysher on 10/31/05.

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
#import "DCMObject.h"


@interface   DCMObject (DCMEncapsulatedPDF) 

+ (id)newEncapsulatedPDF:(NSData *)pdf;



@end
