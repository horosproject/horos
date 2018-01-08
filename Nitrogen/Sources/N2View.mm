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

#import <N2View.h>
#import <N2Layout.h>
#import <N2Operators.h>

NSString* N2ViewBoundsSizeDidChangeNotification = @"N2ViewBoundsSizeDidChangeNotification";
NSString* N2ViewBoundsSizeDidChangeNotificationOldBoundsSize = @"oldBoundsSize";

@interface N2View (Dummy)

- (id)additionalSubviews;

@end

@implementation N2View
@synthesize controlSize = _controlSize, minSize = _minSize, maxSize = _maxSize, layout = _layout, foreColor = _foreColor, backColor = _backColor;


-(void)dealloc {
	[self setForeColor:NULL];
	[self setBackColor:NULL];
	[self setLayout:NULL];
	[super dealloc];
}

-(void)resizeSubviews {
	[self resizeSubviewsWithOldSize:[self bounds].size];
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
	[_layout layOut];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:N2ViewBoundsSizeDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSValue valueWithSize:oldBoundsSize] forKey:N2ViewBoundsSizeDidChangeNotificationOldBoundsSize]]];
}

-(void)formatSubview:(NSView*)view {
	if (view) {
		if (_foreColor && [view respondsToSelector:@selector(setTextColor:)])
			[view performSelector:@selector(setTextColor:) withObject:_foreColor];
		if (_backColor && [view respondsToSelector:@selector(setBackgroundColor:)])
			[view performSelector:@selector(setBackgroundColor:) withObject:_backColor];
		else if ([view respondsToSelector:@selector(setDrawsBackground:)])
			[(NSText*)view setDrawsBackground:NO];
		//if ([view respondsToSelector:@selector(setFont:)] && [view performSelector:@selector(font)])
		//	[view performSelector:@selector(setFont:) withObject:[NSFont fontWithName:[[view performSelector:@selector(font)] fontName] size:[NSFont systemFontSizeForControlSize:[self controlSize]]]];
	} else
		view = self;
	
	for (NSView* subview in [view subviews])
		if (![subview isKindOfClass:[N2View class]] || [(N2View*)subview layout] == NULL)
			[self formatSubview:subview];
	if ([view respondsToSelector:@selector(additionalSubviews)])
		for (NSView* subview in [view performSelector:@selector(additionalSubviews)])
			if (![subview isKindOfClass:[N2View class]] || [(N2View*)subview layout] == NULL)
				[self formatSubview:subview];
}

-(void)didAddSubview:(NSView*)view {
	[self formatSubview:view];
}

-(void)setForeColor:(NSColor*)color {
	[_foreColor release];
	_foreColor = [color retain];
	for (NSView* view in [self subviews])
		[self formatSubview:view];
}

/*-(void)drawRect:(NSRect)rect { // for debugging purposes we may need to identify the view's borders
	[super drawRect:rect];
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	
	[[NSColor redColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] stroke];
	
	[context restoreGraphicsState];
}*/

-(NSSize)optimalSize {
	if (_layout)
		return n2::ceil([_layout optimalSize]);
	else return [self frame].size;	
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	if (_layout)
		return n2::ceil([_layout optimalSizeForWidth:width]);
	else return [self frame].size;
}

@end

