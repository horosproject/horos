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

#import <N2Layout.h>
#import <N2View.h>
#import <N2Operators.h>
#import <N2Exceptions.h>

@implementation N2Layout
@synthesize view = _view, controlSize = _controlSize, margin = _margin, forcesSuperviewHeight = _forcesSuperviewHeight, forcesSuperviewWidth = _forcesSuperviewWidth, separation = _separation, enabled = _enabled;

-(id)initWithView:(N2View*)view controlSize:(NSControlSize)size {
	self = [super init];
	_view = view;
	[view setLayout:self];
	[self setEnabled:YES];
	
	switch (_controlSize = size) {
		case NSRegularControlSize:
			_margin = NSMakeRect(NSMakePoint(17,17), NSMakeSize(34));
			_separation = NSMakeSize(2,6);
			break;
		case NSSmallControlSize:
			_margin = NSMakeRect(NSMakePoint(10,10), NSMakeSize(20));
			_separation = NSMakeSize(2,3);
			break;
		case NSMiniControlSize:
			_margin = NSMakeRect(NSMakePoint(5,5), NSMakeSize(10));
			_separation = NSMakeSize(1,1);
			break;
	}
	
//	_fontSize = [NSFont systemFontSizeForControlSize:size];

	return self;
}

-(void)layOutImpl {
	[NSException raise:N2VirtualMethodException format:@"Method -[%@ layOut] must be defined", [self className]];	
}

-(void)layOut {
	if (!_enabled) return;
	
	if (_layingOut) return;
	_layingOut = YES;
	
	[_view formatSubview:NULL];
	[self layOutImpl];
	
	_layingOut = NO;
}

-(NSSize)optimalSize {
	[NSException raise:N2VirtualMethodException format:@"Method -[%@ optimalSize] must be defined", [self className]];	
	return NSZeroSize;
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	[NSException raise:N2VirtualMethodException format:@"Method -[%@ optimalSizeForWidth:] must be defined", [self className]];	
	return NSZeroSize;
}

/*
 -(void)adaptSubview:(NSView*)view {
	if (_foreColor && [view respondsToSelector:@selector(setTextColor:)])
		[(NSTextView*)view setTextColor:_foreColor];
	if (_backColor && [view respondsToSelector:@selector(setBackgroundColor:)])
		[(NSTextView*)view setBackgroundColor:_backColor];
	if (!_backColor && [view respondsToSelector:@selector(setDrawsBackground:)])
		[(NSTextView*)view setDrawsBackground:NO];
	//	if ([view respondsToSelector:@selector(setFont:)])
	//		[(NSTextView*)view setFont:[NSFont labelFontOfSize:_fontSize]];
	//	if ([view respondsToSelector:@selector(cell)])
	//		[[(NSControl*)view cell] setControlSize:_controlSize];
	
	//	if ([view respondsToSelector:@selector(setDrawsBackground:)])
	//		[(NSTextView*)view setDrawsBackground:YES];
	//	if ([view respondsToSelector:@selector(setBackgroundColor:)])
	//		[(NSTextView*)view setBackgroundColor:[NSColor blueColor]];
}

-(void)didAddSubview:(NSView*)view {
	[self adaptSubview:view];
	
	for (NSView* subview in [view subviews])
		if (![subview isKindOfClass:[N2View class]] || [(N2View*)subview layout] == NULL)
			[self didAddSubview:subview];
}

-(NSRect)marginFor:(NSView*)view {
	if ([view isKindOfClass:[NSTextView class]])
		return NSMakeRect(-3,0, -6,0);
	// TO DO: others, specially buttons
	return NSMakeRect(0, 0, 0, 0);
}

-(void)recalculate:(N2View*)view {
	DLog(@"[N2LayoutManager recalculate]");
	
	NSRect bounds = [view bounds];
	if (!_occupiesEntireSuperview) {
		bounds.origin += _padding.origin;
		bounds.size -= _padding.size;
	}
	NSArray* content = [view content];
	
	CGFloat maxWidth = 0;
	CGFloat rowWidths[[content count]], rowViewCounts[[content count]];
	
	// detect needed width
	for (int i = [content count]-1; i >= 0; --i) {
		rowWidths[i] = 0;
		rowViewCounts[i] = 0;
		for (NSView* view in [content objectAtIndex:i])
			if ([view isKindOfClass:[NSView class]]) {
				++rowViewCounts[i];
				rowWidths[i] += std::ceil([view frame].size.width)+_separation.width+[self marginFor:view].size.width;
			}
		rowWidths[i] -= _separation.width;
		maxWidth = std::max(maxWidth, rowWidths[i]);
	}
	
	if (_stretchesToFill)
		maxWidth = bounds.size.width;
	
	// move views
	CGFloat y = 0;
	for (int i = [content count]-1; i >= 0; --i) {
		NSArray* row = [content objectAtIndex:i];
		CGFloat xFactor = 1;
		if (_stretchesToFill)
			xFactor = (maxWidth-_separation.width*(rowViewCounts[i]-1))/rowWidths[i];
		CGFloat x = 0, maxHeight = 0;
		for (NSView* view in row)
			if ([view isKindOfClass:[NSView class]]) {
				NSRect frame = [view frame], viewMargin = [self marginFor:view];
				frame.origin = NSMakePoint(x,y)+bounds.origin+viewMargin.origin;
				if (xFactor != 0) frame.size.width *= xFactor;
				else frame.size.width = maxWidth;
				[view setFrame:frame];
				x += std::ceil(frame.size.width)+_separation.width+viewMargin.size.width;
				maxHeight = std::max(maxHeight, std::ceil([view frame].size.height)+viewMargin.size.height);
			}
		
//		CGFloat difference = bounds.size.width - x;
//		if (_occupiesEntireSuperview && difference > 0) {
//			CGFloat availableWidth = bounds.size.width - _separation.width*([row count]-1);
//			x = 0;
//			for (NSView* view in row) {
//				NSRect frame = [view frame];
//				frame.size.width *= 
//			}
//		}
	
		y += maxHeight+_separation.height;
	}
	
	NSSize size = NSMakeSize(maxWidth, y-_separation.height);
	if (!_occupiesEntireSuperview) {
		size += _padding.size;
		bounds.origin -= _padding.origin;
		bounds.size += _padding.size;
	}
	
//	size.width -= 2;
	NSWindow* window = [view window];
	if (_forcesSuperviewSize && !NSEqualSizes(size, [view bounds].size))
		if (view == [window contentView]) {
			NSRect frame = [window frame];
			NSSize oldFrameSize = frame.size;
			frame.size = [window frameRectForContentRect:NSMakeRect(NSZeroPoint, size)].size;
			frame.origin = frame.origin - (frame.size - oldFrameSize);
			[window setFrame:frame display:YES];
			[window setMinSize:[window frameRectForContentRect:NSMakeRect(0,0,[window minSize].width, size.height)].size]; // TO DO: x minmax must be kept
			[window setMaxSize:[window frameRectForContentRect:NSMakeRect(0,0,[window maxSize].width, size.height)].size]; // TO DO: x minmax must be kept
		} else [view setFrameSize:size];
}

-(void)setForeColor:(NSColor*)color {
	if (_foreColor) [_foreColor release];
	_foreColor = [color retain];
}
 */

-(void)setForeColor:(NSColor*)color {
	// temporarily here for backwards compatibility with the Arthroplasty Templating II plugin
}

@end
