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

#import "N2HighlightImageButtonCell.h"


@implementation N2HighlightImageButtonCell

-(id)initWithImage:(NSImage*)image {
	self = [super initImageCell:image];
	
	self.gradientType = NSGradientNone;
	self.bezelStyle = 0;
	
	return self;
}

+(NSImage*)highlightedImage:(NSImage*)image {
	NSImage* highlightedImage = NULL;

	NSUInteger w = image.size.width, h = image.size.height;
	highlightedImage = [[NSImage alloc] initWithSize:image.size];
	[highlightedImage lockFocus];
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	
	for (NSUInteger y = 0; y < h; ++y)
		for (NSUInteger x = 0; x < w; ++x) {
			NSColor* c = [bitmap colorAtX:x y:y];
			c = [c highlightWithLevel:[c alphaComponent]/1.5];
			[bitmap setColor:c atX:x y:y];
		}
	
	[bitmap draw]; [bitmap release];
	[highlightedImage unlockFocus];
	
	return [highlightedImage autorelease];	
}

-(BOOL)isOpaque {
	return NO;
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view {
	NSImage* image = self.image;
	if (![self isHighlighted])
		image = [N2HighlightImageButtonCell highlightedImage:image];
	NSRect imageFrame = NSZeroRect; imageFrame.size = image.size;
	[image drawInRect:frame fromRect:imageFrame operation:NSCompositeSourceOver fraction:1];
}

-(void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView {
}



@end
