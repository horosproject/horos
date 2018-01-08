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

#import "CIALayoutView.h"
#import "CIAPlaceHolder.h"
#import "CIAAnnotation.h"
#import "NSBezierPath_RoundRect.h"
#import <QuartzCore/CoreAnimation.h>

@implementation CIAPlaceHolder

#define TOP_MARGIN 5.0
#define BOTTOM_MARGIN 5.0
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
		animatedFrameSize = frame.size;
		align = CIAPlaceHolderAlignLeft;
		orientationWidgetPosition = CIAPlaceHolderOrientationWidgetTop;
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
}

- (void)addAnnotation:(CIAAnnotation*)anAnnotation;
{
	[self addAnnotation:anAnnotation animate:YES];
}

- (void)addAnnotation:(CIAAnnotation*)anAnnotation animate:(BOOL)animate;
{
	[self insertAnnotation:anAnnotation atIndex:[annotationsArray count] animate:animate];
}

- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index;
{
	[self insertAnnotation:anAnnotation atIndex:index animate:YES];
}

- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index animate:(BOOL)animate;
{
	[[anAnnotation placeHolder] removeAnnotation:anAnnotation];
	
	if(orientationWidgetPosition == CIAPlaceHolderOrientationWidgetTop)
	{
		if(index==0 && [annotationsArray count]>0)
			if([[annotationsArray objectAtIndex:0] isOrientationWidget])
				index = 1;
	}
	else if(orientationWidgetPosition == CIAPlaceHolderOrientationWidgetBottom)
	{
		if(index==[annotationsArray count] && [annotationsArray count]>0)
			if([[annotationsArray lastObject] isOrientationWidget])
				index = [annotationsArray count] - 1;
	}
			
	if([anAnnotation isOrientationWidget])
	{
		if(orientationWidgetPosition == CIAPlaceHolderOrientationWidgetTop)
			[annotationsArray insertObject:anAnnotation atIndex:0];
		else if(orientationWidgetPosition == CIAPlaceHolderOrientationWidgetBottom)
			[annotationsArray addObject:anAnnotation];
	}
	else if(index<[annotationsArray count])
		[annotationsArray insertObject:anAnnotation atIndex:index];
	else
		[annotationsArray addObject:anAnnotation];
	
	
	[anAnnotation setPlaceHolder:self];
			
	[self alignAnnotations];
	[self updateFrameAroundAnnotationsWithAnimation:animate];
}

- (BOOL)containsAnnotation:(CIAAnnotation*)anAnnotation;
{
	return [annotationsArray containsObject:anAnnotation];
}

- (NSMutableArray*)annotationsArray;
{
	return annotationsArray;
}

- (void)alignAnnotations;
{
	[self alignAnnotationsWithAnimation:NO];
}

- (void)alignAnnotationsWithAnimation:(BOOL)animate;
{
	float positionX0, positionX, previousY;
	
	if(align==CIAPlaceHolderAlignLeft)
		positionX0 = [self frame].origin.x +3.0;
	else if(align==CIAPlaceHolderAlignCenter)
		positionX0 = [self frame].origin.x + [self frame].size.width / 2.0;
	else if(align==CIAPlaceHolderAlignRight)
		positionX0 = [self frame].origin.x + [self frame].size.width;
		
	previousY = [self frame].origin.y + [self frame].size.height - TOP_MARGIN;
	
	if(animate)
	{
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration: 0.001];
	}
	
	int i;
	CIAAnnotation *currentAnnotation;
	for (i=0; i<[annotationsArray count]; i++)
	{
		currentAnnotation = [annotationsArray objectAtIndex:i];

		positionX = positionX0;
		if(align==CIAPlaceHolderAlignCenter)
			positionX -= [currentAnnotation frame].size.width / 2.0;
		else if(align==CIAPlaceHolderAlignRight)
			positionX -= [currentAnnotation frame].size.width;
		
		NSPoint newOrigin;
		if(i==0)
			newOrigin = NSMakePoint(positionX, previousY-[currentAnnotation frame].size.height);
		else
			newOrigin = NSMakePoint(positionX, previousY-[currentAnnotation frame].size.height+2.0);
		
		if(animate)
			[[currentAnnotation animator] setAnimatedFrameOrigin:newOrigin];
		else
			[currentAnnotation setFrameOrigin:newOrigin];

		previousY = [currentAnnotation frame].origin.y;
	}
	
	if(animate) [NSAnimationContext endGrouping];
	
	[self setNeedsDisplay:YES];
}

- (void)updateFrameAroundAnnotations;
{
	[self updateFrameAroundAnnotationsWithAnimation:YES];
}

- (void)updateFrameAroundAnnotationsWithAnimation:(BOOL)animate;
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
		if([currentAnnotation width] > maxWidth) maxWidth=[currentAnnotation width];
	}
	
	totalHeight += TOP_MARGIN + BOTTOM_MARGIN;
	maxWidth += RIGHT_MARGIN;
	
	if(totalHeight<[CIAPlaceHolder defaultSize].height) totalHeight = [CIAPlaceHolder defaultSize].height;
	
	NSSize newSize = NSMakeSize(maxWidth,totalHeight);
	
	NSPoint shift;
	shift.x = [self frame].size.width - newSize.width;
 	shift.y = [self frame].size.height - newSize.height;
	
	if(newSize.height!=[self frame].size.height || newSize.width!=[self frame].size.width)
	{
		if(animate)
		{
			[[NSAnimationContext currentContext] setDuration:0.1];
			[[self animator] setAnimatedFrameSize:newSize];
		}
		else
			[self setAnimatedFrameSize:newSize];
	}
	[(CIALayoutView*)[self superview] updatePlaceHolderOrigins];
}

- (NSSize)animatedFrameSize;
{
	return animatedFrameSize;
}

- (void)setAnimatedFrameSize:(NSSize)size;
{
	animatedFrameSize = size;
	[self setFrameSize:animatedFrameSize];
	[[self superview] setNeedsDisplay:YES];
}

+ (id)defaultAnimationForKey:(NSString *)key
{
	if ([key isEqualToString:@"animatedFrameSize"])
	{
		return [CABasicAnimation animation];
	}
	else
	{
		return [super defaultAnimationForKey:key];
	}
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
	NSPoint oldOrigin = [self frame].origin;
	NSPoint shift;
	shift.x = newOrigin.x - oldOrigin.x;
	shift.y = newOrigin.y - oldOrigin.y;

	int i;
	for (i=0; i<[annotationsArray count]; i++)
	{
		NSPoint origin = [[annotationsArray objectAtIndex:i] frame].origin;
		origin.x += shift.x;
		origin.y -= shift.y;
		[[annotationsArray objectAtIndex:i] setFrameOrigin:origin];
	}
	
	[super setFrameOrigin:newOrigin];
	[self alignAnnotations];
}

- (void)setAlignment:(CIAPlaceHolderAlignement)alignement;
{
	align = alignement;
}

- (void)setOrientationWidgetPosition:(CIAPlaceHolderOrientationWidgetPosition)pos;
{
	orientationWidgetPosition = pos;
}

@end
