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

#import "CIAAnnotation.h"
#import "CIAPlaceHolder.h"
#import "NSBezierPath_RoundRect.h"
#import <QuartzCore/CoreAnimation.h>

@interface NSColor (randomColor)

+ (NSColor*)randomColor;

@end

@implementation NSColor (randomColor)

+ (NSColor*)randomColor;
{
	float r = round((float)rand()/(float)RAND_MAX * 2.0) / 2.0;
	float g = round((float)rand()/(float)RAND_MAX * 2.0) / 2.0;
	float b = round((float)rand()/(float)RAND_MAX * 2.0) / 2.0;
	return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
}

@end

@implementation CIAAnnotation

+ (NSSize)defaultSize;
{
	return NSMakeSize(75, 22);
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
	{
		isSelected = NO;
		placeHolder = nil;
		color = [[NSColor orangeColor] retain];
		backgroundColor = [[NSColor redColor] retain];
		[self setTitle:@"Annotation"];
		content = [[NSMutableArray array] retain];
		isOrientationWidget = NO;
		width = 0;
    }
    return self;
}

- (void)dealloc
{
	[color release];
	[backgroundColor release];
	[title release];
	[content release];
	[super dealloc];
}

-(BOOL)isEnabled {
	NSView* view = self.superview;
	for (; view && ![view isKindOfClass:[NSControl class]]; view = view.superview) ;
	return ((NSControl*)view).isEnabled;
}

- (void)drawRect:(NSRect)rect
{
//	[[NSColor lightGrayColor] set];
//	NSRectFill(rect);

	#define ROUNDED_CORNER_SIZE 3.0
	
	rect = NSMakeRect(rect.origin.x+2.0, rect.origin.y+4.0, rect.size.width-7.0, rect.size.height-7.0);
	
	NSBezierPath *borderFrame = [NSBezierPath bezierPathWithRoundedRect:rect cornerRadius:ROUNDED_CORNER_SIZE];
	
	NSShadow* theShadow;

	theShadow = [[NSShadow alloc] init];
	[theShadow setShadowOffset:NSMakeSize(3.0, -3.0)];
	[theShadow setShadowBlurRadius:3.0];
	[theShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.5]];
	[NSGraphicsContext saveGraphicsState];
	[theShadow set];
	
	// background
	[color set];
	if(isSelected)
		[backgroundColor set];
	if(!self.isEnabled || isOrientationWidget)
		[[NSColor grayColor] set];
	[borderFrame fill];

	[NSGraphicsContext restoreGraphicsState];
	[theShadow release];
	
	// border
	[borderFrame setLineWidth:1.0];
	if(isSelected)
		[borderFrame setLineWidth:2.0];
		
	[[NSColor redColor] set];
	if(!self.isEnabled || isOrientationWidget)
		[[NSColor darkGrayColor] set];
	[borderFrame stroke];
	
	// text
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attrsDictionary setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	[paragraphStyle release];

	NSFont *font = [NSFont systemFontOfSize:10.0];
	[attrsDictionary setObject:font forKey:NSFontAttributeName];
	
	NSAttributedString *contentText = [[[NSAttributedString alloc] initWithString:title attributes:attrsDictionary] autorelease];
	
	[contentText drawInRect:NSMakeRect(rect.origin.x, rect.origin.y-1.0, rect.size.width, rect.size.height)];
	//[contentText drawInRect:rect];	
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if(!self.isEnabled || isOrientationWidget) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CIAAnnotationMouseDraggedNotification" object:self];
	
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint eventLocationInView = [self convertPoint:eventLocation fromView:nil];
	
	float deltaX = eventLocationInView.x-mouseDownLocation.x;//[theEvent deltaX];
	float deltaY = mouseDownLocation.y-eventLocationInView.y;//[theEvent deltaY];
	float newX = [self frame].origin.x+deltaX;
	float newY = [self frame].origin.y-deltaY;
	
	NSPoint newOrigin = [self frame].origin; // = NSMakePoint([self frame].origin.x+deltaX,[self frame].origin.y-deltaY);
	animatedFrameOrigin = newOrigin;
	
	BOOL needsDisplay = NO;
	if(newX>0.0 && newX+[self frame].size.width<[[self superview] frame].size.width)
	{
		newOrigin.x = newX;
		needsDisplay = YES;
	}
	
	if(newY>0.0 && newY+[self frame].size.height<[[self superview] frame].size.height)
	{
		newOrigin.y = newY;
		needsDisplay = YES;
	}
	
	if(needsDisplay)
	{
		[self setFrameOrigin:newOrigin];
		[[self superview] setNeedsDisplay:YES];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if(!self.isEnabled || isOrientationWidget) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CIAAnnotationMouseDownNotification" object:self];
	NSPoint eventLocation = [theEvent locationInWindow];
	mouseDownLocation = [self convertPoint:eventLocation fromView:nil];
}

- (NSPoint)mouseDownLocation;
{
	return mouseDownLocation;
}

- (void)setMouseDownLocation:(NSPoint)newLocation;
{
	mouseDownLocation = newLocation;
}

- (void)recomputeMouseDownLocation;
{
	NSPoint eventLocation = [[[NSApplication sharedApplication] currentEvent] locationInWindow];
	mouseDownLocation = [self convertPoint:eventLocation fromView:nil];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if(!self.isEnabled || isOrientationWidget) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CIAAnnotationMouseUpNotification" object:self];
}

- (void)setIsSelected:(BOOL)boo;
{
	isSelected = boo;
}

- (CIAPlaceHolder*)placeHolder;
{
	return placeHolder;
}

- (void)setPlaceHolder:(CIAPlaceHolder*)aPlaceHolder;
{
	placeHolder = aPlaceHolder;
}

- (NSString*)title;
{
	return title;
}

- (void)setTitle:(NSString*)aTitle;
{
	if([aTitle isEqualToString:@""]) return;
	if(title) [title release];
	title = [aTitle retain];

	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	NSFont *font = [NSFont systemFontOfSize:10.0];
	[attrsDictionary setObject:font forKey:NSFontAttributeName];
	NSAttributedString *contentText = [[[NSAttributedString alloc] initWithString:title attributes:attrsDictionary] autorelease];
	NSRect textBounds = [contentText boundingRectWithSize:[self bounds].size options:NSStringDrawingUsesDeviceMetrics];
	
	[self setFrameSize:NSMakeSize(textBounds.size.width +6.0*ROUNDED_CORNER_SIZE, [self frame].size.height)];
	width = textBounds.size.width +6.0*ROUNDED_CORNER_SIZE;
	[self setNeedsDisplay:YES];
}

- (NSMutableArray*)content;
{
	return content;
}

- (void)setContent:(NSArray*)newContent;
{
	[content setArray:newContent];
}

- (int)countOfContent;
{
	return [content count];
}

- (NSString*)objectInContentAtIndex:(unsigned)index;
{
	return [content objectAtIndex:index];
}

- (void)getContent:(NSString **)strings range:(NSRange)inRange;
{
    [content getObjects:strings range:inRange];
}

- (void)insertObject:(NSString *)string inContentAtIndex:(unsigned int)index;
{
	[content insertObject:string atIndex:index];
}
 
- (void)removeObjectFromContentAtIndex:(unsigned int)index;
{
	[content removeObjectAtIndex:index];
}

- (BOOL)isOrientationWidget;
{
	return isOrientationWidget;
}

- (void)setIsOrientationWidget:(BOOL)boo;
{
	isOrientationWidget = boo;
}

- (float)width
{
	return width;
}

- (NSPoint)animatedFrameOrigin;
{
	return animatedFrameOrigin;
}

- (void)setFrameOrigin:(NSPoint)newOrigin;
{
	animatedFrameOrigin = newOrigin;
	[super setFrameOrigin:newOrigin];
}

- (void)setAnimatedFrameOrigin:(NSPoint)newOrigin;
{
	animatedFrameOrigin = newOrigin;
	[super setFrameOrigin:newOrigin];
	[[self superview] setNeedsDisplay:YES];
}

+ (id)defaultAnimationForKey:(NSString *)key
{
	//if([key isEqualToString:@"frameOrigin"])
	if([key isEqualToString:@"animatedFrameOrigin"])
	{
		return [CABasicAnimation animation];
	}
	else
	{
		return [super defaultAnimationForKey:key];
	}
}

@end
