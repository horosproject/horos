//
//  NFIFrame.m
//  CustomWindow
//
//  Created by Sean Patrick O'Brien on 9/15/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFIFrame.h"

#import "CTGradient.h"
#import "EtchedTextCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFIFrame

- (id)initWithFrame:(NSRect)frame styleMask:(unsigned int)style owner:(id)o
{
	self = [super initWithFrame:frame styleMask:style owner:o];
	mTitleBarHeight = 25.0f;
	mBottomBarHeight = 0;
	mMidBarOriginY = 0;
	mMidBarHeight = 0;
	
	mInnerGradient = [[CTGradient gradientWithBeginningColor: [self gradientStartColor]
						endingColor:[self gradientEndColor]] retain];
	mOuterGradient = [[CTGradient gradientWithBeginningColor: [self gradient2StartColor]
						endingColor:[self gradient2EndColor]] retain];
								
	titleCell = [[EtchedTextCell alloc] initTextCell: @""];
	[titleCell setFont:[NSFont fontWithName:@"LucidaGrande" size:13.0]];
	[titleCell setShadowColor:[NSColor whiteColor]];
	
	return self;
}

- (NSSize)_topCornerSize
{
	return NSMakeSize(0, [self titleBarHeight]);
}

+ (NSBezierPath*)_clippingPathForFrame:(NSRect)aRect
{
	float radius = [self cornerRadius];
	NSBezierPath *path = [NSBezierPath alloc];
	NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
	NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
	NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
	NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));

	[path moveToPoint: topMid];
	[path appendBezierPathWithArcFromPoint: topRight
		toPoint: bottomRight
		radius: radius];
	[path appendBezierPathWithArcFromPoint: bottomRight
		toPoint: aRect.origin
		radius: radius];
	[path appendBezierPathWithArcFromPoint: aRect.origin
		toPoint: topLeft
		radius: radius];
	[path appendBezierPathWithArcFromPoint: topLeft
		toPoint: topRight
		radius: radius];
	[path closePath];
	
	return path;
}

- (void)_drawTitle:(NSRect)rect
{
	[self _drawTitleStringIn:rect withColor:[self titleColor]];
}

- (void)_drawTitleBar:(NSRect)rect
{
	[[self topWindowEdgeColor] set];
	NSRectFill(rect);
	rect.size.height--;
	[[self bottomEdgeColor] set];
	NSRectFill(rect);
	rect.size.height++;
	
	NSRect gradientRect = rect;
	gradientRect.origin.y++;
	gradientRect.size.height -= 2;
	[mOuterGradient fillRect: gradientRect angle:-90.0f];
	gradientRect.origin.x++;
	gradientRect.size.width -= 2;
	[mInnerGradient fillRect: gradientRect angle:-90.0f];
	
	NSImage *topLeft = [NSImage frameworkImageNamed: @"IWWindowCornerTL"];
	NSImage *topRight = [NSImage frameworkImageNamed: @"IWWindowCornerTR"];
	
	[topLeft compositeToPoint:NSMakePoint(rect.origin.x,
				rect.origin.y + [self titleBarHeight] - [topLeft size].height) operation: NSCompositeSourceOver];
	[topRight compositeToPoint:NSMakePoint(rect.origin.x + rect.size.width-[topRight size].width,
				rect.origin.y + [self titleBarHeight] - [topLeft size].height) operation: NSCompositeSourceOver];
	
	[self _drawTitle:rect];
}

- (void)_drawMidBar:(NSRect)rect
{
	[[self bottomWindowEdgeColor] set];
	NSRectFill(rect);
	rect.origin.y++;
	rect.size.height--;
	[[self bottomEdgeColor] set];
	NSRectFill(rect);
	rect.size.height -= 2;
	rect.origin.y++;
	[[self edgeColor] set];
	NSRectFill(rect);
	rect.size.height += 3;
	rect.origin.y -= 2;
	
	NSRect gradientRect = rect;
	gradientRect.origin.y++;
	gradientRect.size.height -= 3;
	[mOuterGradient fillRect: gradientRect angle:-90.0f];
	gradientRect.origin.x++;
	gradientRect.size.width -= 2;
	[mInnerGradient fillRect: gradientRect angle:-90.0f];
}

- (void)_drawBottomBar:(NSRect)rect
{
	[[self bottomWindowEdgeColor] set];
	NSRectFill(rect);
	rect.origin.y++;
	rect.size.height--;
	[[self bottomEdgeColor] set];
	NSRectFill(rect);
	rect.size.height -= 2;
	rect.origin.y++;
	[[self edgeColor] set];
	NSRectFill(rect);
	rect.size.height += 3;
	rect.origin.y -= 2;
	
	NSRect gradientRect = rect;
	gradientRect.origin.y++;
	gradientRect.size.height -= 3;
	[mOuterGradient fillRect: gradientRect angle:-90.0f];
	gradientRect.origin.x++;
	gradientRect.size.width -= 2;
	[mInnerGradient fillRect: gradientRect angle:-90.0f];
	
	NSImage *bottomLeft = [NSImage frameworkImageNamed: @"IWWindowCornerBL"];
	NSImage *bottomRight = [NSImage frameworkImageNamed: @"IWWindowCornerBR"];
	
	[bottomLeft compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y) operation: NSCompositeSourceOver];
	[bottomRight compositeToPoint:NSMakePoint(rect.origin.x + rect.size.width-[bottomRight size].width, rect.origin.y) operation: NSCompositeSourceOver];
}

- (void)drawRect:(NSRect)_rect
{
	NSRect rect = [self bounds];
	[[NSColor clearColor] set];
	NSRectFill(rect);
	NSRectFill(_rect);
	
	NSBezierPath *path = [[self class] _clippingPathForFrame: rect];
	[path addClip];
	
	[[self backgroundColor] set];
	
	NSRectFill(rect);
	
	NSRect titleBarRect = rect;
	titleBarRect.origin.y += rect.size.height - [self titleBarHeight];
	titleBarRect.size.height = [self titleBarHeight];
	
	NSRect bottomBarRect = rect;
	bottomBarRect.size.height = [self bottomBarHeight];
	
	NSRect midBarRect = rect;
	midBarRect.origin.y += [self midBarOriginY];
	midBarRect.size.height = [self midBarHeight];

	[self _drawMidBar: midBarRect];
	[self _drawTitleBar: titleBarRect];
	[self _drawBottomBar: bottomBarRect];
}

- (void)_drawGrowBoxWithClip:(NSRect)rect
{
	rect.origin.x += 3;
	rect.origin.y += 2;
	NSImage *resize = [NSImage frameworkImageNamed:@"IWWindowResizeControl"];
	[resize compositeToPoint:rect.origin operation: NSCompositeSourceOver];
}

- (float)titleBarHeight
{
	if([self _toolbarIsShown])
		return mTitleBarHeight + [self _distanceFromToolbarBaseToTitlebar];
	return mTitleBarHeight;
}

- (void)setTitleBarHeight:(float)height
{
	mTitleBarHeight = height;
	[self setNeedsDisplay:YES];
}

- (float)bottomBarHeight
{
	return mBottomBarHeight;
}

- (void)setBottomBarHeight:(float)height
{
	mBottomBarHeight = height;
	[self setNeedsDisplay:YES];
}

- (float)midBarHeight
{
	return mMidBarHeight;
}

- (float)midBarOriginY
{
	return mMidBarOriginY;
}

- (void)setMidBarHeight:(float)height origin:(float)origin
{
	mMidBarHeight = height;
	mMidBarOriginY = origin;
	[self setNeedsDisplay:YES];
}

- (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(unsigned int)aStyle
{
    frameRect.size.height -= 25;//[self titleBarHeight];
    return frameRect;
}

- (NSRect)frameRectForContentRect:(NSRect)windowContent styleMask:(unsigned int)aStyle
{
    windowContent.size.height += 25;//[self titleBarHeight];
    return windowContent;
}

- (void)_showToolbarWithAnimation:(BOOL)animate
{
	[super _showToolbarWithAnimation:animate];
	[self setNeedsDisplay:YES];
}

- (id)backgroundColor
{
	return [NSColor colorWithCalibratedWhite: 224/255.0 alpha: 1.0];
}

- (id)gradientStartColor
{
	return [NSColor colorWithCalibratedWhite: 197/255.0 alpha: 1.0];
}

- (id)gradientEndColor
{
	return [NSColor colorWithCalibratedWhite: 150/255.0 alpha: 1.0];
}

- (id)gradient2StartColor
{
	return [NSColor colorWithCalibratedWhite: 179/255.0 alpha: 1.0];
}

- (id)gradient2EndColor
{
	return [NSColor colorWithCalibratedWhite: 139/255.0 alpha: 1.0];
}

- (id)edgeColor
{
	return [NSColor colorWithCalibratedWhite: 226/255.0 alpha: 1.0];
}

- (id)bottomEdgeColor
{
	return [NSColor colorWithCalibratedWhite: 102/255.0 alpha: 1.0];
}

- (id)topWindowEdgeColor
{
	return [NSColor colorWithCalibratedWhite: 222/255.0 alpha: 1.0];
}

- (id)bottomWindowEdgeColor
{
	return [NSColor colorWithCalibratedWhite: 65/255.0 alpha: 1.0];
}

- (id)titleColor
{
	if([[self window] isMainWindow])
		return [NSColor colorWithCalibratedWhite:0 alpha:0.9];
	return [NSColor colorWithCalibratedWhite:0 alpha:0.50];
}

+ (float)cornerRadius
{
	return 5.0;
}

@end
