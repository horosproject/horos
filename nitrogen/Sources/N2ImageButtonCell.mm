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

#import "N2ImageButtonCell.h"


@implementation N2ImageButtonCell

@synthesize altImage;

-(id)initWithImage:(NSImage*)image altImage:(NSImage*)inAltImage {
	self = [super initImageCell:image];
	
	if (inAltImage) // because subclassers might have assigned this through setImage
		self.altImage = inAltImage;
	
	self.gradientType = NSGradientNone;
	self.bezelStyle = 0;
	
	return self;
}

-(BOOL)isOpaque {
	return NO;
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view {
	NSImage* image = self.image;
	if (![self isHighlighted])
		image = self.altImage;
	NSRect imageFrame = NSZeroRect; imageFrame.size = image.size;
	[image drawInRect:frame fromRect:imageFrame operation:NSCompositeSourceOver fraction:1];
}

-(void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView {
}

@end
