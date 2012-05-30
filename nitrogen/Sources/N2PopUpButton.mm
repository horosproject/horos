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

#import "N2PopUpButton.h"
#import "N2Operators.h"


@interface N2PopUpButtonCell : NSPopUpButtonCell
@end
@implementation N2PopUpButtonCell

-(void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)view {
	[super drawBezelWithFrame:frame inView:view];
	static NSImage* image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"PopUpArrows" ofType:@"png"]];
	static NSSize imageSize = [image size];
	[self drawImage:image withFrame:NSMakeRect(NSMakePoint(frame.origin.x+frame.size.width-imageSize.width-6, frame.origin.y+(frame.size.height-imageSize.height)/2), imageSize) inView:view];
}

@end

@implementation N2PopUpButton

-(void)customize {
	[self setBezelStyle:NSRecessedBezelStyle];
	[self setImagePosition:NSImageRight];
}

-(id)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag {
	self = [super initWithFrame:buttonFrame pullsDown:flag];
	[self customize];
	return self;
}

-(void)awakeFromNib {
	[self customize];
}

@end
