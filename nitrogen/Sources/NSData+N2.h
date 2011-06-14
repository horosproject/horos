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


@interface NSData (N2)

+(NSData*)dataWithHex:(NSString*)hex;
-(NSData*)initWithHex:(NSString*)hex;
+(NSData*)dataWithBase64:(NSString*)base64;
-(NSData*)initWithBase64:(NSString*)base64;
-(NSString*)base64;
-(NSString*)hex;
-(NSData*)md5;

@end
