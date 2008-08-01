/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "ROI.h"
#import "HistogramWindow.h"
#import "DCMPix.h"

@implementation HistoWindow

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	free( data);
	
	[super dealloc];
}

- (void) removeROI :(NSNotification*) note
{
	if( [note object] == curROI)
	{
		[self release];
	}
}

- (void) changeWLWW :(NSNotification*) note
{
	if( [note object] == [curROI pix])
	{
		long i;
		
		[self changeBin: binSlider];
	}
}

- (void) roiChange :(NSNotification*) note
{
	if( [note object] == curROI)
	{
		long i;
		
		if( data) free( data);
		data = [curROI dataValuesAsFloatPointer: &dataSize];
	
		long fullwl = [[curROI pix] fullwl];
		long fullww = [[curROI pix] fullww];
		
		minValue = fullwl - fullww/2;
		maxValue = fullwl + fullww/2;
		
		[self changeBin: binSlider];
	}
}

- (IBAction) changeBin: (id) sender
{
	long	i, dL, max = 0;
	
	for( i = 0; i < HISTOSIZE; i++) histoData[ i] = 0;
	
	for( i = 0; i < dataSize; i++)
	{
		dL = ((data[ i] - minValue) * (HISTOSIZE-1)) / (maxValue - minValue);
		
		if( dL < 0) dL = 0;
		if( dL > (HISTOSIZE-1)) dL = (HISTOSIZE-1);
		
		histoData[ dL] ++;
		
		if( histoData[ dL] > max) max = histoData[ dL];
	}
	
	[histo setRange: minValue :maxValue];
	[histo setMaxValue: max :dataSize];
	[histo setData: histoData :HISTOSIZE :[sender intValue]]; 
	
	[maxText setIntValue: max];
	
	[binText setIntValue: ([sender intValue] * (maxValue-minValue)) / HISTOSIZE];
}


- (id) initWithROI: (ROI*) iroi
{
	self = [super initWithWindowNibName:@"Histogram"];
	
	[[self window] setFrameAutosaveName:@"HistogramWindow"];
	
	data = 0L;
	curROI = iroi;
	
	[[self window] setTitle: [NSString stringWithFormat:NSLocalizedString(@"Histogram of '%@' ROI", nil), [curROI name]]];
	
	[histo setCurROI: curROI];
	
	if( data) free(data);
	data = [curROI dataValuesAsFloatPointer: &dataSize];
	
	long fullwl = [[curROI pix] fullwl];
	long fullww = [[curROI pix] fullww];
	
	minValue = fullwl - fullww/2;
	maxValue = fullwl + fullww/2;
	
	[self changeBin: binSlider];
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(removeROI:)
               name: @"removeROI"
             object: nil];
			 
	[nc addObserver: self
		   selector: @selector(roiChange:)
			   name: @"roiChange"
			 object: nil];
			 
	[nc addObserver: self
		   selector: @selector(changeWLWW:)
			   name: @"changeWLWW"
			 object: nil];
	
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self release];
}

-(ROI*) curROI {return curROI;}

@end
