//
//  N2ImageButtonCell.mm
//  OsiriX
//
//  Created by Alessandro Volz on 7/19/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

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
