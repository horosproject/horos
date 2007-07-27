//
//  CIAAnnotation.m
//  ImageAnnotations
//
//  Created by joris on 25/06/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "CIAAnnotation.h"
#import "CIAPlaceHolder.h"
#import "NSBezierPath_RoundRect.h"

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
	[borderFrame fill];

	[NSGraphicsContext restoreGraphicsState];
	[theShadow release];
	
	// border
	[borderFrame setLineWidth:1.0];
	if(isSelected)
		[borderFrame setLineWidth:2.0];
		
	[[NSColor redColor] set];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CIAAnnotationMouseDraggedNotification" object:self];
	
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint eventLocationInView = [self convertPoint:eventLocation fromView:nil];
	
	float deltaX = eventLocationInView.x-mouseDownLocation.x;//[theEvent deltaX];
	float deltaY = mouseDownLocation.y-eventLocationInView.y;//[theEvent deltaY];
	float newX = [self frame].origin.x+deltaX;
	float newY = [self frame].origin.y-deltaY;
	
	NSPoint newOrigin = [self frame].origin; // = NSMakePoint([self frame].origin.x+deltaX,[self frame].origin.y-deltaY);
	
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
//	NSLog(@"recomputeMouseDownLocation>>>>");
//	NSLog(@"mouseDownLocation : %f, %f", mouseDownLocation.x, mouseDownLocation.y);
	NSPoint eventLocation = [[[NSApplication sharedApplication] currentEvent] locationInWindow];
	mouseDownLocation = [self convertPoint:eventLocation fromView:nil];
//	NSLog(@"mouseDownLocation : %f, %f", mouseDownLocation.x, mouseDownLocation.y);
//	NSLog(@"<<<<<<");
}

- (void)mouseUp:(NSEvent *)theEvent
{
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
	[self setNeedsDisplay:YES];
}

- (NSMutableArray*)content;
{
	NSLog(@"content");
	return content;
}

- (void)setContent:(NSArray*)newContent;
{
	NSLog(@"setContent");
	[content setArray:newContent];
}

- (int)countOfContent;
{
	NSLog(@"countOfContent");
	return [content count];
}

- (NSString*)objectInContentAtIndex:(unsigned)index;
{
	NSLog(@"objectInContentAtIndex");
	return [content objectAtIndex:index];
}

- (void)getContent:(NSString **)strings range:(NSRange)inRange;
{
	NSLog(@"getContent:range:");
    [content getObjects:strings range:inRange];
}

- (void)insertObject:(NSString *)string inContentAtIndex:(unsigned int)index;
{
	NSLog(@"insertObject:inContentAtIndex:");
	[content insertObject:string atIndex:index];
}
 
- (void)removeObjectFromContentAtIndex:(unsigned int)index;
{
	NSLog(@"removeObjectFromContentAtIndex:");
	[content removeObjectAtIndex:index];
}


@end
