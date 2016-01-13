/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import <Cocoa/Cocoa.h>


extern NSString* N2NonNullString(NSString* s);

@interface NSString (N2)

-(NSString*)markedString;
-(NSString *)stringByTruncatingToLength:(NSInteger)theWidth;
+(NSString*)sizeString:(unsigned long long)size;
+(NSString*)timeString:(NSTimeInterval)time;
+(NSString*)timeString:(NSTimeInterval)time maxUnits:(NSInteger)maxUnits;
+(NSString*)dateString:(NSTimeInterval)date;
-(NSString*)stringByTrimmingStartAndEnd;

-(NSString*)urlEncodedString __deprecated; // use 
-(NSString*)xmlEscapedString;
-(NSString*)xmlUnescapedString;

-(NSString*)ASCIIString;

-(BOOL)contains:(NSString*)str;

-(NSString*)stringByPrefixingLinesWithString:(NSString*)prefix;
+(NSString*)stringByRepeatingString:(NSString*)string times:(NSUInteger)times;
-(NSString*)suspendedString;

-(NSRange)range;

//-(NSString*)resolvedPathString;
-(NSString*)stringByComposingPathWithString:(NSString*)rel;

-(NSArray*)componentsWithLength:(NSUInteger)len;

-(BOOL)isEmail;

-(void)splitStringAtCharacterFromSet:(NSCharacterSet*)charset intoChunks:(NSString**)part1 :(NSString**)part2 separator:(unichar*)separator;

-(NSString*)md5;

@end

@interface NSAttributedString (N2)

-(NSRange)range;

@end;