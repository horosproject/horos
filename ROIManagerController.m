/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/



#import "ROIManagerController.h"

@implementation ROIManagerController

- (id) initWithViewer:(ViewerController*) v
{
	viewer = 0L;
	
	self = [super initWithWindowNibName:@"ROIManager"];
	
	[[self window] setFrameAutosaveName:@"ROIManagerWindow"];
	
	// register to notification
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: @"roiChange"
             object: nil];
	[nc addObserver: self
           selector: @selector(fireUpdate:)
               name: @"removeROI"
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: @"DCMUpdateCurrentImage"
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: @"roiSelected"
             object: nil];
		 
	viewer = v;
	DCMPix	*curPix = [[viewer pixList] objectAtIndex:0];
	pixelSpacingZ = [curPix sliceInterval];
	
	[self fireUpdate: 0L];
	
	return self;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	int i;
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	ROI				*editedROI = [curRoiList objectAtIndex: rowIndex];
	NSString		*oldName = [NSString stringWithString:[editedROI name]];
	

//	[editedROI setName:anObject];
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:editedROI userInfo: 0L];
	
	[viewer renameSeriesROIwithName: [editedROI name] newName:anObject];
	
	[tableView reloadData];
}

- (void) keyDown:(NSEvent *)event
{
	unichar c = [[event characters] characterAtIndex:0];
    if( c == 127)
	{
		[self deleteROI: self];
	}
}



- (IBAction)deleteROI:(id)sender
{
	int i;
	unsigned long index;
	NSMutableArray* names = [NSMutableArray arrayWithCapacity:1];
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	
	if ((index == NSNotFound) || index < 0) return;
	
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	
	while ( index != NSNotFound) 
	{
		ROI	*selectedRoi = [curRoiList objectAtIndex:index];
	
		[viewer deleteSeriesROIwithName: [selectedRoi name]];
	
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:selectedRoi userInfo: 0L];
//		[curRoiList removeObject:selectedRoi];
		
		index = [indexSet indexLessThanIndex:index];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateView" object:0L userInfo: 0L];
}

//- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
//{
//	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
//	
//	long i;
//	
//	for( i = 0; i < [curRoiList count]; i++)
//	{
//		ROI	*curROI = [curRoiList objectAtIndex: i];
//		
//		if( [tableView isRowSelected: i])
//		{
//			[curROI setROIMode: ROI_selected];
//		}
//		else
//		{
//			[curROI setROIMode: ROI_sleep];
//		}
//		
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:curROI userInfo: 0L];
//	}
//}

- (void) roiListModification: (NSNotification*) note
{
	[tableView reloadData];
}

- (void) fireUpdate: (NSNotification*) note
{
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(roiListModification:) userInfo:0L repeats:NO];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	
    return [curRoiList count];
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row
{
	if( viewer == 0L) return 0L;
	
	int i,indic;
	float area=0.0;
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	
	if( [[tableColumn identifier] isEqualToString:@"Index"])
	{
		return [NSString stringWithFormat:@"%d", row+1];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"Name"])
	{
		return [[curRoiList objectAtIndex:row] name];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"area"])
	{
		return [NSNumber numberWithFloat:[[curRoiList objectAtIndex:row] roiArea]];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"volume"])
	{
		float volume = [viewer computeVolume:[curRoiList objectAtIndex:row] points:0L error: 0L];
		
		if( volume) return [NSString stringWithFormat:@"%2.2f", volume];
		else return [NSString stringWithString:@"n/a"];
	}
	
	return 0L;
}

// delegate method setROIMode

-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		NSLog( @"ROIManager CloseViewerNotification");
		
		[self close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
 
	NSLog( @"ROIManager windowWillClose");
	[tableView setDataSource: 0L];
	
	[self release];
}

- (void) dealloc
{
	NSLog( @"ROIManager dealloc");
	
	viewer = 0L;
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}
@end
