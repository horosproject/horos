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


extern NSString* N2NonNullString(NSString* s);

@interface NSString (N2)

-(NSString*)markedString;

+(NSString*)sizeString:(unsigned long long)size;
+(NSString*)timeString:(NSTimeInterval)time;
+(NSString*)dateString:(NSTimeInterval)date;
-(NSString*)stringByTrimmingStartAndEnd;

-(NSString*)urlEncodedString __deprecated;
-(NSString*)xmlEscapedString;
-(NSString*)xmlUnescapedString;

-(NSString*)ASCIIString;

-(BOOL)contains:(NSString*)str;

-(NSString*)stringByPrefixingLinesWithString:(NSString*)prefix;
+(NSString*)stringByRepeatingString:(NSString*)string times:(NSUInteger)times;
-(NSString*)suspendedString;

-(NSRange)range;

-(NSString*)resolvedPathString;
-(NSString*)stringByComposingPathWithString:(NSString*)rel;

-(NSArray*)componentsWithLength:(NSUInteger)len;

-(BOOL)isEmail;

@end

@interface NSAttributedString (N2)

-(NSRange)range;

@end;