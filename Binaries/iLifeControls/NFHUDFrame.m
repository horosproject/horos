//
//  NFHUDFrame.m
//  iLife HUD Window
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFHUDFrame.h"
#import "EtchedTextCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFHUDFrame

- (id)initWithFrame:(NSRect)frame styleMask:(unsigned int)style owner:(id)owner
{
	if([super initWithFrame:frame styleMask:style owner:owner])
	{
		// Some of Apple's HUD windows have a slight shadow below the title
		EtchedTextCell *cell = [[EtchedTextCell alloc] initTextCell: @""];
		[cell setFont:[NSFont fontWithName:@"LucidaGrande" size:11.0]];
		[cell setShadowColor:[NSColor colorWithCalibratedWhite:32/255.0 alpha:0.5]];
		titleCell = cell;
		
		// get the regular controls out of the picture
		[closeButton setHidden:YES];
		[minimizeButton setHidden:YES];
		[zoomButton setHidden:YES];
		
		// according to Andy Matuschak, the superclass doesn't do it's job here...
		[[self window] setShowsResizeIndicator:(style & NSResizableWindowMask)];
		
		// close button, in the style of Matt Gemmell's HUD Window implementation
		NSButton *closeWidget = [[NSButton alloc] initWithFrame:NSMakeRect(3.0, [self frame].size.height - 16.0, 
																		   13.0, 13.0)];
		[self addSubview:closeWidget];
		[closeWidget setButtonType:NSMomentaryChangeButton];
		[closeWidget setBordered:NO];
		[closeWidget setImage:[NSImage frameworkImageNamed:@"HUDCloseButton.tiff"]];
		[closeWidget setImagePosition:NSImageOnly];
		[closeWidget setTarget:[self window]];
		[closeWidget setFocusRingType:NSFocusRingTypeNone];
		//[closeWidget setAction:@selector(orderOut:)];
		[closeWidget setAction:@selector(performClose:)];
		[closeWidget setAutoresizingMask:NSViewMinYMargin];
		[closeWidget release];
		
		return self;
	}
	
	return nil;
}

+ (NSBezierPath*)_clippingPathForFrame:(NSRect)aRect
{
	float radius = 6.5;
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

- (NSRect)_titlebarTitleRect
{
	NSRect rect = (NSRect) [super _titlebarTitleRect];
	rect.origin.y++;
	
	return rect;
}

- (void)_drawTitle:(NSRect)rect
{
	[self _drawTitleStringIn:rect withColor:[NSColor whiteColor]];
}

- (void)_drawTitleBar:(NSRect)rect
{
	[[NSColor colorWithCalibratedWhite: 64/255.0 alpha:0.85] set];
	NSRectFill(rect);
	
	[self _drawTitle:rect];
}

- (void)drawRect:(NSRect)_rect
{
	NSRect rect = [self frame];
	[[NSColor clearColor] set];
	NSRectFill(rect);
	NSRectFill(_rect);
	
	NSBezierPath *path = [[self class] _clippingPathForFrame: rect];
	[path addClip];
	
	[[NSColor colorWithCalibratedWhite:32/255.0 alpha:213/255.0] set];
	
	NSRectFill(rect);
	
	NSRect titleBarRect = rect;
	titleBarRect.origin.y += rect.size.height - [self titleBarHeight];
	titleBarRect.size.height = [self titleBarHeight];

	[self _drawTitleBar: titleBarRect];
}

- (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(unsigned int)aStyle
{
	frameRect.size.width -= 2;
	frameRect.origin.x += 1;
    frameRect.size.height -= [self titleBarHeight];
    return frameRect;
}


- (NSRect)frameRectForContentRect:(NSRect)windowContent styleMask:(unsigned int)aStyle
{
	windowContent.size.width += 2;
	windowContent.origin.x -= 1;
    windowContent.size.height += [self titleBarHeight];
    return windowContent;
}

- (NSSize)_topCornerSize
{
	return NSMakeSize(0, [self titleBarHeight]);
}

-(float)titleBarHeight
{
	return 19;
}

// Taken directly from Andy Matuschak's implementation
- (void)_drawResizeIndicators:(NSRect)rect
{
	if (![[self window] showsResizeIndicator])
		return;
	NSPoint resizeOrigin = NSMakePoint(NSMaxX([self frame]) - 3, 3);
	NSBezierPath *resizeGrip = [NSBezierPath bezierPath];
	[resizeGrip moveToPoint:NSMakePoint(resizeOrigin.x, resizeOrigin.y + 2)];
	[resizeGrip lineToPoint:NSMakePoint(resizeOrigin.x - 3, resizeOrigin.y)];
	[resizeGrip moveToPoint:NSMakePoint(resizeOrigin.x, resizeOrigin.y + 6)];
	[resizeGrip lineToPoint:NSMakePoint(resizeOrigin.x - 7, resizeOrigin.y)];
	[resizeGrip moveToPoint:NSMakePoint(resizeOrigin.x, resizeOrigin.y + 10)];
	[resizeGrip lineToPoint:NSMakePoint(resizeOrigin.x - 11, resizeOrigin.y)];		
	[resizeGrip setLineWidth:1.0];
	
	[[NSColor lightGrayColor] set];
	[resizeGrip stroke];	
}

@end
