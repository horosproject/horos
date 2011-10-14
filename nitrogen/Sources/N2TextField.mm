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

#import "N2TextField.h"


@interface N2TextField ()

@property(nonatomic, readwrite) BOOL formatIsOk;

@end


@implementation N2TextField

//@synthesize invalidContentBackgroundColor;
@synthesize formatIsOk;

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	formatIsOk = YES;
	return self;
}

/*-(void)dealloc {
	self.invalidContentBackgroundColor = NULL;
	[super dealloc];
}*/

-(void)updateFormatIsOk {
	if (self.formatter) {
		id obj = NULL;
		
		// ok if filled and respects format
		// also ok if NOT filled and placeholder string defined
		if (self.stringValue.length)
			self.formatIsOk = [self.formatter getObjectValue:&obj forString:self.stringValue errorDescription:NULL];
		else {
			if ([[self cell] placeholderString])
				self.formatIsOk = YES;
			else self.formatIsOk = NO;
		}
		
	/*	if (invalidContentBackgroundColor) {
			[self setBackgroundColor: self.formatIsOk? [NSColor whiteColor] : invalidContentBackgroundColor ];
			[self setNeedsDisplay:YES];
		}*/
	}
}

-(void)setFormatter:(NSFormatter*)newFormatter {
	[super setFormatter:newFormatter];
	[self updateFormatIsOk];
}

-(void)setFormatIsOk:(BOOL)flag {
	if (formatIsOk == flag)
		return;
	formatIsOk = flag;
	[self didChangeValueForKey:@"formatIsOk"];
}

/*-(void)setInvalidContentBackgroundColor:(NSColor*)color {
	[invalidContentBackgroundColor release];
	invalidContentBackgroundColor = [color retain];
	[self checkFormat];
}*/

-(void)keyDown:(NSEvent*)event {
	[super keyDown:event];
	[self updateFormatIsOk];
}

-(void)textDidChange:(NSNotification*)notif {
	[super textDidChange:notif];
	[self updateFormatIsOk];
}

-(void)setObjectValue:(id)value {
	[super setObjectValue:value];
	[self updateFormatIsOk];
}

-(void)setStringValue:(id)value {
	[super setStringValue:value];
	[self updateFormatIsOk];
}

@end
