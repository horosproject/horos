//
//  DCMObjectPixelDataImport.h
//  OsiriX
//
//  Created by Lance Pysher on 11/22/05.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

#import <Cocoa/Cocoa.h>
#import <OsiriX/DCMObject.h>


@interface DCMObjectPixelDataImport : DCMObject {

}

+ (id)objectWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData	;

@end
