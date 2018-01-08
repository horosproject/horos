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

#import <N2DisclosureBox.h>
#import <N2DisclosureButtonCell.h>
#import <N2Operators.h>

NSString* N2DisclosureBoxDidToggleNotification = @"N2DisclosureBoxDidToggleNotification";
NSString* N2DisclosureBoxWillExpandNotification = @"N2DisclosureBoxWillExpandNotification";
NSString* N2DisclosureBoxDidExpandNotification = @"N2DisclosureBoxDidExpandNotification";
NSString* N2DisclosureBoxDidCollapseNotification = @"N2DisclosureBoxDidCollapseNotification";

@implementation N2DisclosureBox

-(id)initWithTitle:(NSString*)title content:(NSView*)content {
    self = [super initWithFrame:NSZeroRect];
	
	// NSBox
	[self setTitlePosition:NSAtTop];
	[self setBorderType:NSBezelBorder];
	[self setBoxType:NSBoxPrimary];
	[self setAutoresizesSubviews:YES];
	
	if (_titleCell) [_titleCell release]; // [NSBox dealloc] will later release the object we will now create
	_titleCell = [[N2DisclosureButtonCell alloc] init];
	[_titleCell setTitle:title];
	[_titleCell setState:NSOffState];
	[_titleCell setTarget:self];
	[_titleCell setAction:@selector(toggle:)];
	
	_content = [content retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:content];
	[self setFrameFromContentFrame:NSZeroRect];
	
    return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_content release];
	[super dealloc];
}

-(void)mouseDown:(NSEvent*)event {
	if (NSPointInRect([event locationInWindow], [self convertRect:[self titleRect] toView:NULL]))
		[_titleCell trackMouse:event inRect:[self titleRect] ofView:self untilMouseUp:YES];
	else [super mouseDown:event];
}

-(BOOL)enabled {
	return [_titleCell isEnabled];
}

-(void)setEnabled:(BOOL)flag {
	[_titleCell setEnabled:flag];
}

-(BOOL)isExpanded {
	return [_titleCell state] == NSOnState;
}

-(N2DisclosureButtonCell*)titleCell {
	return _titleCell;
}

-(void)toggle:(id)sender {
	if ([self isExpanded])
		[self expand:sender];
	else [self collapse:sender];
	[[NSNotificationCenter defaultCenter] postNotificationName:N2DisclosureBoxDidToggleNotification object:self];
}

-(void)expand:(id)sender {
	if (_showingExpanded) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:N2DisclosureBoxWillExpandNotification object:self];
	_showingExpanded = YES;
	
	[self setFrameFromContentFrame:[_content frame]];
	[self addSubview:_content];
	
	[_titleCell setState:NSOnState];
	[[NSNotificationCenter defaultCenter] postNotificationName:N2DisclosureBoxDidExpandNotification object:self];
}

-(void)collapse:(id)sender {
	if (!_showingExpanded) return;
	_showingExpanded = NO;
	
	[_content removeFromSuperview];
	[self setFrameFromContentFrame:NSZeroRect];
	
	[_titleCell setState:NSOffState];
	[[NSNotificationCenter defaultCenter] postNotificationName:N2DisclosureBoxDidCollapseNotification object:self];
}

-(void)contentViewFrameDidChange:(NSNotification*)notification {
	[self setFrameFromContentFrame:[_content frame]];
}

-(void)setFrameFromContentFrame:(NSRect)contentFrame {
	NSSize margins = [self contentViewMargins];
	NSRect frame = contentFrame + NSMakeSize(margins.width*2, [_titleCell textSize].height+margins.height*2);
	if (frame.size != [self frame].size) [self setFrameSize:frame.size];
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
	[super resizeSubviewsWithOldSize:oldBoundsSize];
//	if ([self isExpanded]) [_content setFrameSize:[]];
	[_titleCell calcDrawInfo:[self frame]];
}

-(void)setTitle:(NSString*)title {
	[_titleCell setTitle:title];
	[_titleCell setAlternateTitle:title];
}

-(NSString*)title {
	return [_titleCell title];
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	NSSize size = [self frame].size;
	size.width = width;
	return n2::ceil(size);
}

-(NSArray*)additionalSubviews {
	return [NSArray arrayWithObject:_content];
}

@end
