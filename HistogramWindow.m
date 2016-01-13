/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/




#import "ROI.h"
#import "HistogramWindow.h"
#import "DCMPix.h"
#import "Notifications.h"

@implementation HistoWindow

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
    if( data)
        free( data);
	
    [curROI release];
    
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
		[self changeBin: binSlider];
	}
}

- (void) roiChange :(NSNotification*) note
{
	if( [note object] == curROI)
	{
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
		dL = ((data[ i] - minValue) * HISTOSIZE) / (maxValue - minValue);
		
		if( dL < 0)
            dL = 0;
        
		if( dL > (HISTOSIZE-1))
            dL = (HISTOSIZE-1);
		
		histoData[ dL] ++;
		
		if( histoData[ dL] > max)
            max = histoData[ dL];
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
	
	data = nil;
	curROI = [iroi retain];
	
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
	
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[self autorelease];
}

-(ROI*) curROI {return curROI;}

@end
