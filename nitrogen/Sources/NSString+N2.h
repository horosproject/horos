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


@interface NSString (N2)

-(NSString*)markedString;

+(NSString*)sizeString:(unsigned long long)size;
+(NSString*)timeString:(NSTimeInterval)time;
+(NSString*)dateString:(NSTimeInterval)date;
-(NSString*)stringByTrimmingStartAndEnd;

-(NSString*)urlEncodedString;
-(NSString*)xmlEscapedString;
-(NSString*)xmlUnescapedString;

@end
