/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

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