/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/



#import "PlotView.h"
#import "ROI.h"
#import "DCMPix.h"
#import "DCMView.h"

@implementation PlotView

- (void)mouseDown:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSRect  boundsRect = [self bounds];
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:[[self window] contentView]];
	
	curMousePosition = (loc.x * dataSize) / boundsRect.size.width;
	
	if( curMousePosition < 0) curMousePosition = 0;
	if( curMousePosition >= dataSize) curMousePosition = dataSize-1;
	
//	[mouseValue setFloatValue: dataArray[ curMousePosition]];
	
//	if( [[curROI pix] pixelSpacingX] != 0)
//	{
//		float length = curMousePosition;
//		
//		length *= [[curROI pix] pixelSpacingX];
//		length /= 10;
//		
//		[mousePos setStringValue: [NSString stringWithFormat:@"Pixel %d , %2.2f cm", curMousePosition+1, length]]; 
//	}
//	else
//	[mousePos setStringValue: [NSString stringWithFormat:@"Pixel %d", curMousePosition+1]];
	
	[curROI setMousePosMeasure: (float) curMousePosition / (float) dataSize ];
	[[curROI curView] setNeedsDisplay: YES];
	
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	curMousePosition = -1;
//	[mousePos setStringValue:@""];
//	[mouseValue setStringValue:@""];
	
	[curROI setMousePosMeasure: curMousePosition];
	[[curROI curView] setNeedsDisplay: YES];
	
	[self setNeedsDisplay:YES];
}
 
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		dataArray = nil;
		dataSize = 0;
		curMousePosition = -1;
    }
    return self;
}

- (void)setData:(float*)array :(long) size
{
	dataArray = array;
	dataSize  = size;
	
	[self setNeedsDisplay: YES];
}

-(void) setCurROI: (ROI*) r
{
	curROI = r;
}

- (void)drawRect:(NSRect)aRect
{
	NSRect  boundsRect=[self bounds];
	int		index;
	float	minValue, maxValue;
	
	if( dataArray == nil) return;
	if( dataSize < 2) return;
	
	[[NSColor whiteColor] set];
	NSRectFill(aRect);
	
	minValue = maxValue = dataArray[ 0];
	for(index = 0 ; index < dataSize;index++)  
	{
		if( minValue > dataArray[ index]) minValue = dataArray[ index];
		if( maxValue < dataArray[ index]) maxValue = dataArray[ index];
	}
	
	minValue -= (maxValue - minValue) / 10.;
	maxValue += (maxValue - minValue) / 10.;
	
	NSBezierPath	*plotLine = [NSBezierPath bezierPath];
	
	for(index = 0 ; index < dataSize;index++)  
	{
		float xx, yy;
		long fullwl = [[curROI pix] fullwl];
		long fullww = [[curROI pix] fullww];
	
		long min = fullwl - fullww/2;
		long max = fullwl + fullww/2;
		
		long	wl,ww;
		
		xx = (index * boundsRect.size.width) / (dataSize-1);
		yy = dataArray[ index] - minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		
		if(index == 0)
		{
			[plotLine moveToPoint: NSMakePoint( xx, yy)];
		}
		else
		{
			[plotLine lineToPoint: NSMakePoint( xx, yy)];
		}

		
		wl = [[curROI pix] wl];
		ww = [[curROI pix] ww];
		
		float colVal = min + (index * max) / 255.;
		
		colVal -= wl - ww/2;
		colVal /= ww;
		
		if( colVal < 0) colVal = 0;
		if( colVal > 1.0) colVal = 1.0;
		
		[[NSColor colorWithDeviceRed:colVal green:colVal blue:colVal alpha:1.0] set];
		
	//	NSRectFill(histRect);
	}
	[plotLine setLineWidth: 2];
	
	[[NSColor blackColor] set];
	
	[plotLine stroke];
	
	if( curMousePosition != -1)
	{
		NSString	*trace;
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		NSDictionary	*boldFont = [NSDictionary dictionaryWithObjectsAndKeys:	[NSFont labelFontOfSize:12.0],NSFontAttributeName,
																			[NSColor blackColor],NSForegroundColorAttributeName,
																			paragraphStyle,NSParagraphStyleAttributeName,
																			nil];

		
		

		[[NSColor selectedMenuItemColor] set];
		NSRect lineRect = NSMakeRect( (curMousePosition * boundsRect.size.width)/(dataSize-1), 0, 2, boundsRect.size.height);
		NSRectFill( lineRect);
		
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		
		trace = [NSString stringWithFormat:@"X: %d", (int) curMousePosition+1];
		
		NSSize traceSize = [trace sizeWithAttributes:boldFont];
		NSPoint xLabelPosition;
		xLabelPosition = lineRect.origin;
		xLabelPosition.x += 4;
		if(lineRect.origin.x + traceSize.width + 2 > boundsRect.size.width)
			xLabelPosition.x = boundsRect.size.width - traceSize.width - 2;
		
		[[NSColor whiteColor] set];	
		NSRectFill(NSMakeRect(xLabelPosition.x, xLabelPosition.y, traceSize.width, traceSize.height));
		[[NSColor blackColor] set];
		[trace drawAtPoint:xLabelPosition withAttributes:boldFont];
		
		if( lineRect.origin.x - boundsRect.size.width/2 > 0) [paragraphStyle setAlignment:NSLeftTextAlignment];
		else [paragraphStyle setAlignment:NSRightTextAlignment];
				
		[[NSColor selectedMenuItemColor] set];
		lineRect = NSMakeRect( 0, ((dataArray[ curMousePosition] - minValue) * boundsRect.size.height)/(maxValue- minValue), boundsRect.size.width, 2);
		NSRectFill( lineRect);
		
		trace = [NSString stringWithFormat:@"Y: %2.2f", dataArray[ curMousePosition]];
		
		NSPoint yLabelPosition;
		yLabelPosition = lineRect.origin;
		yLabelPosition.x += 2;
		yLabelPosition.y += 2;

		traceSize = [trace sizeWithAttributes:boldFont];
		[[NSColor whiteColor] set];	
		NSRectFill(NSMakeRect(yLabelPosition.x, yLabelPosition.y, traceSize.width, traceSize.height));
		[trace drawAtPoint:yLabelPosition withAttributes:boldFont];
	}
	
	[[NSColor blackColor] set];
	NSFrameRectWithWidth(aRect, 1.0);
}
@end
