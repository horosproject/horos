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


#import "NSTextView+N2.h"
#import "NS(Attributed)String+Geometrics.h"
#import "N2Operators.h"

@implementation NSTextView (N2)

+(NSTextView*)labelWithText:(NSString*)text {
	return [self labelWithText:text alignment:NSNaturalTextAlignment];
}

+(NSTextView*)labelWithText:(NSString*)text alignment:(NSTextAlignment)alignment {
	NSTextView* ret = [[NSTextView alloc] initWithFrame:NSZeroRect];
	[ret setString:text];
	[ret setAlignment:alignment];
	[ret setEditable:NO];
	[ret setSelectable:NO];
	[ret setFont:[NSFont labelFontOfSize:[NSFont labelFontSize]]];
	return [ret autorelease];
}

-(NSRect)sizeAdjust {
	return NSMakeRect(-3,0,6,0);
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	return n2::ceil([[self textStorage] sizeForWidth:width height:CGFLOAT_MAX]-[self sizeAdjust].size);
}

-(NSSize)optimalSize {
	return [self optimalSizeForWidth:CGFLOAT_MAX];
}

-(NSSize)adaptToContent {
	return [self adaptToContent:CGFLOAT_MAX];
}

-(NSSize)adaptToContent:(CGFloat)maxWidth {
	NSSize stringSize = [self optimalSizeForWidth:maxWidth]+[self sizeAdjust].size;
	[self setFrame:NSMakeRect([self frame].origin, stringSize)];
	return stringSize;
}

@end
