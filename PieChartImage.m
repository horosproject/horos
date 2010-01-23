/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "PieChartImage.h"

@implementation NSImage (PieChartImage)

+ (NSImage*) pieChartImageWithPercentage:(float)percentage;
{
	NSColor *fullColor = [NSColor colorWithCalibratedRed:0.4 green:0.8 blue:0.2 alpha:1.0];
	NSColor *insideColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	NSColor *borderColor = [NSColor colorWithCalibratedRed:1.0 green:0.4 blue:0.0 alpha:1.0];
	return [NSImage pieChartImageWithPercentage:percentage borderColor:borderColor insideColor:insideColor fullColor:fullColor];
}

+ (NSImage*) pieChartImageWithPercentage:(float)percentage borderColor:(NSColor*)borderColor insideColor:(NSColor*)insideColor fullColor:(NSColor*)fullColor;
{
	NSRect pieRect = NSMakeRect(0,0,14.0,14.0);
	NSImage* pieImage = [[self alloc] initWithSize:pieRect.size];
	[pieImage setScalesWhenResized:YES];
	
	if( [pieImage size].width > 0 && [pieImage size].height > 0)
	{
		[pieImage lockFocus];
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSRect targetRect = NSInsetRect(pieRect, 2.0, 2.0);

		NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:targetRect];
		
		if(percentage==0)
		{	
			// Fill the circle
			[insideColor set];
			[circle fill];

			// Stroke the circle
			[circle setLineWidth:1.0];	
			[borderColor set];
			[circle stroke];
		}
		else if(percentage==1)
		{
			// Fill the circle
			[fullColor set];
			[circle fill];

			// Stroke the circle
			[circle setLineWidth:1.0];	
			[fullColor set];
			[circle stroke];
		}
		else
		{
			// Fill the circle
			[borderColor set];
			[circle fill];

			// Stroke the circle
			[circle setLineWidth:1.0];	
			[borderColor set];
			[circle stroke];
			
			float startingAngle = (1.0-percentage*4.0)*90.0;
			NSBezierPath* pie = [NSBezierPath bezierPathForPieInRect:targetRect withWedgeRemovedFromStartingAngle:startingAngle toEndingAngle:90.0];

			// Fill the pie
			[insideColor set];
			[pie fill];
			[[NSGraphicsContext currentContext] restoreGraphicsState];
		}
		
		[pieImage unlockFocus];
	}
	
	return [pieImage autorelease];
}

@end

@implementation NSBezierPath (RSPieChartUtilities)

+ (NSBezierPath*) bezierPathForPieInRect:(NSRect)containerRect withWedgeRemovedFromStartingAngle:(float)startAngle toEndingAngle:(float)endAngle
{
	// Creating an arc by swapping the start and finish angles
	NSRect pieRect = NSInsetRect(containerRect, 1.0, 1.0);
	NSBezierPath* piePath = [NSBezierPath bezierPath];
	
	float pieRadius = NSWidth(pieRect) / 2.0;	// assume a square rect
	NSPoint centerPoint = NSMakePoint(NSMidX(pieRect), NSMidY(pieRect));
	[piePath appendBezierPathWithArcWithCenter:centerPoint radius:pieRadius startAngle:endAngle endAngle:startAngle];
	[piePath lineToPoint:centerPoint];
	[piePath closePath];
	return piePath;
}

@end