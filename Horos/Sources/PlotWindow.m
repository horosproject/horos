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
