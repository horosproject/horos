/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

#import "N2ColorWell.h"
#import "NSButton+N2.h"
#import <algorithm>

@interface N2ColorWellCell : NSButtonCell {
}

@end
@implementation N2ColorWellCell

-(void)drawBezelWithFrame:(NSRect)frame inView:(N2ColorWell*)colorWell {
	[NSGraphicsContext saveGraphicsState];
	
	[super drawBezelWithFrame:frame inView:colorWell];
	
	NSRect colorRect = NSInsetRect(frame, std::max(CGFloat(5), frame.size.width/10), std::max(CGFloat(3), frame.size.height/3));
	[[[colorWell color] colorWithAlphaComponent:0.5] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:colorRect xRadius:colorRect.size.height/2 yRadius:colorRect.size.height/2] fill];
	colorRect = NSInsetRect(colorRect, 1, 1);
	[[colorWell color] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:colorRect xRadius:colorRect.size.height/2 yRadius:colorRect.size.height/2] fill];

	[NSGraphicsContext restoreGraphicsState];
}

@end


@implementation N2ColorWell
@synthesize color = _color;

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	NSCell* cell = [[N2ColorWellCell alloc] init];
	[cell setControlSize:NSMiniControlSize];
	[self setCell:cell];
	[cell release];
	
	[self setBezelStyle:NSRecessedBezelStyle];
	[self setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
	
	[self setTitle:@""];
	[self setAction:@selector(click:)];
	[self setTarget:self];
	
	return self;
}

-(void)dealloc {
	[self setColor:NULL];
	[super dealloc];
}

-(void)setColor:(NSColor*)color {
	[_color release];
	_color = [color retain];
	[self setNeedsDisplay:YES];
}

-(void)takeColorFrom:(id)sender {
	[self setColor:[sender color]];
}

-(void)click:(NSNotification*)notification {
	NSColorPanel* panel = [NSColorPanel sharedColorPanel];
//	if (![panel isVisible] || [panel target] != self) {
		[panel setTarget:self];
		[panel setAction:@selector(takeColorFrom:)];
		[panel setShowsAlpha:NO];
		[panel setColor:[self color]];
		[panel setContinuous:YES];
		[panel orderFront:self];
//	} else [panel orderOut:self];
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	if (NSIsEmptyRect([self frame]))
		return [super optimalSizeForWidth:width];
	return [self frame].size;
}

@end
