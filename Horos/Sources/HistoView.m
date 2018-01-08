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




#import "HistogramWindow.h"
#import "HistoView.h"
#import "ROI.h"
#import "DCMPix.h"

@implementation HistoView

- (void)mouseDown:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSRect  boundsRect = [self bounds];
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:[[self window] contentView]];
	
	curMousePosition = (loc.x * dataSize) / boundsRect.size.width;
	
	curMousePosition /= bin;
	curMousePosition *= bin;
	
	if( curMousePosition < 0) curMousePosition = 0;
	if( curMousePosition >= dataSize-1) curMousePosition = dataSize-1;
	
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	curMousePosition = -1;
	
	[self setNeedsDisplay:YES];
}

- (void) dealloc
{
	[backgroundColor release];
	[binColor release];
	[selectedBinColor  release];
	[textColor release];
	[borderColor release];
    [curROI release];
	
	[super dealloc];
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		curMousePosition = -1;
		backgroundColor = [[NSColor whiteColor] retain];
		binColor = [[NSColor lightGrayColor] retain];
		selectedBinColor = [[NSColor selectedMenuItemColor] retain];
		textColor = [[NSColor blackColor] retain];
		borderColor = [[NSColor grayColor] retain];
    }
    return self;
}

- (void)setData:(float*)array :(long) size :(long) b
{
	dataArray=array;
	dataSize = size;
	bin = b;
	
	[self setNeedsDisplay: YES];
}

-(void)setMaxValue: (float) max :(long) p
{
	maxValue = max;
	pixels = p;
}

-(void) setCurROI: (ROI*) r
{
    [curROI release];
	curROI = [r retain];
}

- (void)setRange:(long) mi :(long) max
{
	minV = mi;
	maxV = max;
}

- (void)drawRect:(NSRect)aRect
{
	NSRect					boundsRect=[self bounds];
	int						index, i, noAtMouse = 0;
	float					maxX = (boundsRect.origin.x+boundsRect.size.width)/HISTOSIZE;
	NSString				*trace;
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
//	NSDictionary			*boldFont = [NSDictionary dictionaryWithObjectsAndKeys:	[NSFont labelFontOfSize:10.0],NSFontAttributeName,
//																					[NSColor blackColor],NSForegroundColorAttributeName,
//																					paragraphStyle,NSParagraphStyleAttributeName,
//																					nil];
	NSDictionary			*boldFont = [NSDictionary dictionaryWithObjectsAndKeys:	[NSFont labelFontOfSize:10.0],NSFontAttributeName,
																					textColor,NSForegroundColorAttributeName,
																					paragraphStyle,NSParagraphStyleAttributeName,
																					nil];
//	[[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.2 alpha:1.0] set];
	[backgroundColor set];
	NSRectFill(boundsRect);
    
	for(index = 0 ; index < dataSize;index++)  
	{
		float value = 0;
		
		for( i = 0 ; i < bin; i++)
		{
			if( index+i < dataSize) value += dataArray[index+i];
		}
		
		float height = ((value*boundsRect.size.height)/maxValue)/bin;
		
		NSRect   histRect=NSMakeRect( index * maxX, 0, (bin * maxX)+1.0, height);
		
		long fullwl = [[curROI pix] fullwl];
		long fullww = [[curROI pix] fullww];

		long min = fullwl - fullww/2;
		long max = fullwl + fullww/2;
		
		long	wl,ww;
		
		wl = [[curROI pix] wl];
		ww = [[curROI pix] ww];
		
		float colVal = min + (index * max) / 255.;
		
		colVal -= wl - ww/2;
		colVal /= ww;
		
		if( colVal < 0) colVal = 0;
		if( colVal > 1.0) colVal = 1.0;
		
		[[NSColor colorWithDeviceRed:colVal green:colVal blue:colVal alpha:1.0] set];
		
		if( index  == curMousePosition) 
		{
			//[[NSColor redColor] set];
			[selectedBinColor set];
			noAtMouse = value;
		}
		else
		{
			//[[NSColor blackColor] set];
			[binColor set];
		}
		
		NSRectFill(histRect);
		
		index += bin-1;
	}
	
	if( curMousePosition != -1)
	{
		long ss, ee;
		
		ss = minV + ((curMousePosition) * (maxV-minV)) / dataSize;
		ee = minV + ((curMousePosition+bin) * (maxV-minV)) / dataSize;
        
        if( curMousePosition > 0)
            ss++;
        
		trace = [NSString stringWithFormat:NSLocalizedString(@"Total Pixels: %d\n\nRange:%d/%d\n\nPixels for\nthis range:%d", nil), pixels, ss, ee, noAtMouse];
	}
	else
	{
		trace = [NSString stringWithFormat:NSLocalizedString(@"Total Pixels: %d", nil), pixels];
	}
	
	NSRect dstRect = boundsRect;
	dstRect.origin.x+=4;
	[trace drawInRect: dstRect withAttributes: boldFont];
	
	//[[NSColor blackColor] set];
	[borderColor set];
	NSFrameRectWithWidth(boundsRect, 1.0);
}

- (NSColor*)backgroundColor
{
	return backgroundColor;
}

- (NSColor*)binColor;
{
	return binColor;
}

- (NSColor*)selectedBinColor;
{
	return selectedBinColor;
}

- (NSColor*)textColor;
{
	return textColor;
}

- (NSColor*)borderColor;
{
	return borderColor;
}

- (void)setBackgroundColor:(NSColor*)aColor;
{
	backgroundColor = aColor;
}

- (void)setBinColor:(NSColor*)aColor;
{
	binColor = aColor;
}

- (void)setSelectedBinColor:(NSColor*)aColor;
{
	selectedBinColor = aColor;
}

- (void)setTextColor:(NSColor*)aColor;
{
	textColor = aColor;
}

- (void)setBorderColor:(NSColor*)aColor;
{
	borderColor = aColor;
}

@end
