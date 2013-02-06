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

#import "ROI.h"
#import "PlotWindow.h"
#import "DCMPix.h"
#import "Notifications.h"

@implementation PlotWindow

- (void) refresh
{
	long	i;
	float	iY, aY;
	
	if( data) free( data);
	data = [curROI dataValuesAsFloatPointer: &dataSize];
	
	iY = aY = data[ 0];
	for( i = 0 ; i < dataSize; i++)
	{
		if( iY > data[ i]) iY = data[ i];
		if( aY < data[ i]) aY = data[ i];
	}
	
	[minY setFloatValue: iY];
	[maxY setFloatValue: aY];
	[sizeT setIntValue: aY - iY];
	
//	if( [[curROI pix] pixelSpacingX] != 0)
//	{
//		float length = dataSize;
//		
//		length *= [[curROI pix] pixelSpacingX];
//		length /= 10;
//		
//		[maxX setStringValue: [NSString stringWithFormat:@"%d pixels, %2.2f cm", dataSize, length]]; 
//		
//	}
//	else
	
	[maxX setStringValue: [NSString stringWithFormat:NSLocalizedString(@"%d pixels", nil), dataSize]]; 
	
	[plot setData: data :dataSize]; 
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	if( data) free( data);
	
	[super dealloc];
}


- (void) removeROI :(NSNotification*) note
{
	if( [note object] == curROI)
	{
		[[self window] close];
	}
}

- (void) changeWLWW :(NSNotification*) note
{
	if( [note object] == [curROI pix])
	{
		[plot setNeedsDisplay: YES];
	}
}

- (void) roiChange :(NSNotification*) note
{
    if( [note.name isEqualToString: OsirixRecomputeROINotification] || [note object] == curROI)
		[self refresh];
}

- (id) initWithROI: (ROI*) iroi
{
	self = [super initWithWindowNibName:@"Plot"];
	
	[[self window] setFrameAutosaveName:@"PlotWindow"];
	
	data = nil;
	curROI = iroi;
	
	[[self window] setTitle: [NSString stringWithFormat:NSLocalizedString(@"Plot of '%@' line", nil), [curROI name]]];
	
	[plot setCurROI: curROI];
	
	[self refresh]; 
	
	long fullwl = [[curROI pix] fullwl];
	long fullww = [[curROI pix] fullww];
	
	minValue = fullwl - fullww/2;
	maxValue = fullwl + fullww/2;
	
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(removeROI:)
               name: OsirixRemoveROINotification
             object: nil];
			 
	[nc addObserver: self
		   selector: @selector(roiChange:)
			   name: OsirixROIChangeNotification
			 object: nil];
			 
	[nc addObserver: self
		   selector: @selector(changeWLWW:)
			   name: OsirixChangeWLWWNotification
			 object: nil];
    
    [nc addObserver: self
		   selector: @selector(roiChange:)
			   name: OsirixRecomputeROINotification
			 object: nil];
    
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[self autorelease];
}

-(ROI*) curROI {return curROI;}

@end
