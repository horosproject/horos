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



#import "ROIManagerController.h"

@implementation ROIManagerController

- (id) initWithViewer:(ViewerController*) v
{
	viewer = nil;
	
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
	
	[self fireUpdate: nil];
	
	return self;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(NSInteger)rowIndex
{
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	ROI				*editedROI = [curRoiList objectAtIndex: rowIndex];
	

//	[editedROI setName:anObject];
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:editedROI userInfo: nil];
	
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
	NSInteger index;
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	
	if ((index == NSNotFound) || index < 0) return;
	
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	
	while ( index != NSNotFound) 
	{
		ROI	*selectedRoi = [curRoiList objectAtIndex:index];
	
		[viewer deleteSeriesROIwithName: [selectedRoi name]];
	
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:selectedRoi userInfo: nil];
//		[curRoiList removeObject:selectedRoi];
		
		index = [indexSet indexLessThanIndex:index];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateView" object:nil userInfo: nil];
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
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:curROI userInfo: nil];
//	}
//}

- (void) roiListModification: (NSNotification*) note
{
	[tableView reloadData];
}

- (void) fireUpdate: (NSNotification*) note
{
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(roiListModification:) userInfo:nil repeats:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	
    return [curRoiList count];
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row
{
	if( viewer == nil) return nil;
	
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
		float volume = [viewer computeVolume:[curRoiList objectAtIndex:row] points:nil error: nil];
		
		if( volume)
		{
			if( volume < 10)
				return [NSString stringWithFormat:@"%2.5f", volume];
			else
				return [NSString stringWithFormat:@"%2.2f", volume];
		}
		else return [NSString stringWithString:@"n/a"];
	}
	
	return nil;
}

// delegate method setROIMode

-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		NSLog( @"ROIManager CloseViewerNotification");
		
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
 
	NSLog( @"ROIManager windowWillClose");
	
	[self release];
}

- (void) dealloc
{
	NSLog( @"ROIManager dealloc");
	[tableView setDataSource: nil];
	viewer = nil;
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}
@end
