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


@interface NSTextView (N2)

+(NSTextView*)labelWithText:(NSString*)string;
+(NSTextView*)labelWithText:(NSString*)string alignment:(NSTextAlignment)alignment;

-(NSSize)adaptToContent;
-(NSSize)adaptToContent:(CGFloat)maxWidth;

-(NSSize)optimalSizeForWidth:(CGFloat)width;
-(NSSize)optimalSize;

@end
