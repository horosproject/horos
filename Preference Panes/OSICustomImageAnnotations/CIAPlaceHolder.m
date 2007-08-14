//
//  CIAPlaceHolder.m
//  ImageAnnotations
//
//  Created by joris on 25/06/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "CIALayoutView.h"
#import "CIAPlaceHolder.h"
#import "CIAAnnotation.h"
#import "NSBezierPath_RoundRect.h"

@implementation CIAPlaceHolder

#define TOP_MARGIN 10.0
#define BOTTOM_MARGIN 10.0
#define RIGHT_MARGIN 4.0

+ (NSSize)defaultSize;
{
	NSSize AnnotationSize = [CIAAnnotation defaultSize];
	return NSMakeSize(AnnotationSize.width+5+RIGHT_MARGIN, AnnotationSize.height+TOP_MARGIN+BOTTOM_MARGIN);
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		hasFocus = NO;
		annotationsArray = [[NSMutableArray arrayWithCapacity:0] retain];
    }
    return self;
}

- (void)dealloc
{
	[annotationsArray release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	#define ROUNDED_CORNER_SIZE 5.0
		
	rect = NSMakeRect(rect.origin.x+2.0, rect.origin.y+2.0, rect.size.width-4.0, rect.size.height-4.0);
	
	NSBezierPath *borderFrame = [NSBezierPath bezierPathWithRoundedRect:rect cornerRadius:ROUNDED_CORNER_SIZE];

	CGFloat array[2];
	array[0] = 5.0; //segment painted with stroke color
	array[1] = 2.0; //segment not painted with a color
 
	[borderFrame setLineDash:array count:2 phase:0.0];

	if(hasFocus)
		[[[NSColor controlHighlightColor] colorWithAlphaComponent:0.5] set];
	else
		[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
	[borderFrame fill];
	
	[borderFrame setLineWidth:2.0];
	[[NSColor grayColor] set];
	[borderFrame stroke];
	
	// text
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attrsDictionary setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	[paragraphStyle release];

	NSFont *font = [NSFont systemFontOfSize:10.0];
	[attrsDictionary setObject:font forKey:NSFontAttributeName];
	
	NSAttributedString *contentText = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", [annotationsArray count]] attributes:attrsDictionary] autorelease];
	//[contentText drawInRect:rect];

}

- (BOOL)hasFocus;
{
	return hasFocus;
}

- (void)setHasFocus:(BOOL)boo;
{
	hasFocus = boo;
}

- (BOOL)hasAnnotations;
{
	return [annotationsArray count]>0;
}

- (void)removeAnnotation:(CIAAnnotation*)anAnnotation;
{
	[annotationsArray removeObject:anAnnotation];
	[anAnnotation setPlaceHolder:nil];

	[self alignAnnotations];
	[self updateFrameAroundAnnotations];
	[self alignAnnotations];
	
	[(CIALayoutView*)[self superview] updatePlaceHolderOrigins];
}

- (void)addAnnotation:(CIAAnnotation*)anAnnotation;
{
	[self insertAnnotation:anAnnotation atIndex:[annotationsArray count]];
}

- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index;
{
//	if(![self isEqualTo:[anAnnotation placeHolder]])
	{
		[[anAnnotation placeHolder] removeAnnotation:anAnnotation];
		if(index<[annotationsArray count])
			[annotationsArray insertObject:anAnnotation atIndex:index];
		else
			[annotationsArray addObject:anAnnotation];
		[anAnnotation setPlaceHolder:self];
	}
//	else
//	{
//	}
	
	[self alignAnnotations];
	[self updateFrameAroundAnnotations];
	[self alignAnnotations];
	
	[(CIALayoutView*)[self superview] updatePlaceHolderOrigins];
}

- (NSMutableArray*)annotationsArray;
{
	return annotationsArray;
}

- (void)alignAnnotations;
{
	float positionX = [self frame].origin.x +3.0;

	float totalHeight = 0.0;
	float previousY = [self frame].origin.y + [self frame].size.height - TOP_MARGIN ;
	
	int i;
	CIAAnnotation *currentAnnotation;
	for (i=0; i<[annotationsArray count]; i++)
	{
		currentAnnotation = [annotationsArray objectAtIndex:i];
		totalHeight += [currentAnnotation frame].size.height;
		if(i==0)
			[currentAnnotation setFrameOrigin:NSMakePoint(positionX, previousY-[currentAnnotation frame].size.height)];
		else
			[currentAnnotation setFrameOrigin:NSMakePoint(positionX, previousY-[currentAnnotation frame].size.height+2.0)];
		previousY = [currentAnnotation frame].origin.y;
	}
}

- (void)updateFrameAroundAnnotations;
{
	float totalHeight = 0.0;
	float maxWidth = [CIAPlaceHolder defaultSize].width - RIGHT_MARGIN;;
	int i;
	CIAAnnotation *currentAnnotation;
	for (i=0; i<[annotationsArray count]; i++)
	{
		currentAnnotation = [annotationsArray objectAtIndex:i];
		if(i==0)
			totalHeight += [currentAnnotation frame].size.height;
		else
			totalHeight += [currentAnnotation frame].size.height-2.0;
		if([currentAnnotation frame].size.width > maxWidth) maxWidth=[currentAnnotation frame].size.width;
	}
	
	totalHeight += TOP_MARGIN + BOTTOM_MARGIN;
	maxWidth += RIGHT_MARGIN;
	
	if(totalHeight<[CIAPlaceHolder defaultSize].height) totalHeight = [CIAPlaceHolder defaultSize].height;
	
//	if([self frame].origin.y + totalHeight >= [[self superview] bounds].size.height)
//	{
//		[self setFrameOrigin:NSMakePoint([self frame].origin.x, [[self superview] bounds].size.height - totalHeight)];
//	}
	[self setFrameSize:NSMakeSize(maxWidth,totalHeight)];
}

- (void)setEnabled:(BOOL)enabled;
{
	int i;
	for (i=0; i<[annotationsArray count]; i++)
		[[annotationsArray objectAtIndex:i] setEnabled:enabled];
}

@end
