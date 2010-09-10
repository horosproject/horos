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


#import "NSView+N2.h"
#import "N2Operators.h"


@implementation NSView (N2)

-(id)initWithSize:(NSSize)size {
	return [self initWithFrame:NSMakeRect(NSZeroPoint, size)];
}

-(NSRect)sizeAdjust {
	return NSZeroRect;
}

- (NSImage *) screenshotByCreatingPDF {
	NSData *imageData = [self dataWithPDFInsideRect: [self bounds]];
	return [[[NSImage alloc] initWithData: imageData] autorelease];
}
@end
