//
//  ROIVolumeManagerController.m
//  OsiriX
//
//  Created by joris on 1/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ROIVolumeManagerController.h"
#import "ROIVolume.h"
//#import "ColorWellCell.h"

@implementation ROIVolumeManagerController

- (id) initWithViewer:(NSWindowController*) v
{	
	roiVolumes = [[NSMutableArray alloc] initWithCapacity:0];
	[roiVolumes setArray:[v roiVolumes]];

	self = [super initWithWindowNibName:@"ROIVolumeManager"];

	viewer = v;
		
//	[self setRoiVolumes:[v roiVolumes]];
	
	int i;
	
	//[[self window] setFrameAutosaveName:@"ROIVolumeManagerWindow"];
	
	// register to notification
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(Window3DClose:)
               name: @"Window3DClose"
             object: nil];
//	[nc addObserver: self
//           selector: @selector(roiListModification:)
//               name: @"roiChange"
//             object: nil];
//	[nc addObserver: self
//           selector: @selector(fireUpdate:)
//               name: @"removeROI"
//             object: nil];
//	[nc addObserver: self
//           selector: @selector(roiListModification:)
//               name: @"DCMUpdateCurrentImage"
//             object: nil];
//	[nc addObserver: self
//           selector: @selector(roiListModification:)
//               name: @"roiSelected"
//             object: nil];
	[tableView setDataSource:self];
	//[tableView setDelegate:self];

	return self;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
//NSLog(@"tableView:setObjectValue:forTableColumn:row:");

	if( [[aTableColumn identifier] isEqualToString:@"display"])
	{
		//[[roiVolumes objectAtIndex:rowIndex] setVisible:[anObject boolValue]];
		[[[roiVolumesController arrangedObjects] objectAtIndex:rowIndex] setVisible:[anObject boolValue]];
		if([anObject boolValue])
		{
			//[viewer displayROIVolumeAtIndex: rowIndex];
			[viewer displayROIVolume: [[roiVolumesController arrangedObjects] objectAtIndex:rowIndex]];
		}
		else
		{
			//[viewer hideROIVolumeAtIndex: rowIndex];
			[viewer hideROIVolume: [[roiVolumesController arrangedObjects] objectAtIndex:rowIndex]];
		}
		[[viewer view] display];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"name"])
	{
	}
	else if( [[aTableColumn identifier] isEqualToString:@"volume"])
	{
	}
	else if( [[aTableColumn identifier] isEqualToString:@"red"])
	{
		[[[roiVolumesController arrangedObjects] objectAtIndex:rowIndex] setRed:[anObject floatValue]];
		[[viewer view] display];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"green"])
	{
		[[[roiVolumesController arrangedObjects] objectAtIndex:rowIndex] setGreen:[anObject floatValue]];
		[[viewer view] display];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"blue"])
	{
		[[[roiVolumesController arrangedObjects] objectAtIndex:rowIndex] setBlue:[anObject floatValue]];
		[[viewer view] display];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"opacity"])
	{
		[[[roiVolumesController arrangedObjects] objectAtIndex:rowIndex] setOpacity:[anObject floatValue]];
		[[viewer view] display];
	}
//	else if( [aTableColumn isEqualTo:columnColor])
//	{
//		[[roiVolumes objectAtIndex:rowIndex] setColor:anObject];
//		[[viewer view] display];
//	}
	[tableView reloadData];
}

- (int) numberOfRowsInTableView:(NSTableView *)tableView
{
//	NSLog(@"numberOfRowsInTableView : [[self roiVolumes] count] : %d", [[self roiVolumes] count]);
//	NSLog(@"numberOfRowsInTableView : [roiVolumes count] : %d", [roiVolumes count]);
    return [[self roiVolumes] count];
}

//- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
//{
////NSLog(@"tableView:objectValueForTableColumn:row:");
//	if( viewer == 0L) return 0L;
//	
//	if( [tableColumn isEqualTo:columnDisplay])
//	{
//		return [NSNumber numberWithBool:[[roiVolumes objectAtIndex:row] visible]];
//	}
//	else if( [tableColumn isEqualTo:columnName])
//	{
//		return [[roiVolumes objectAtIndex:row] name];
//	}
//	else if( [tableColumn isEqualTo:columnVolume])
//	{
//		return [NSNumber numberWithFloat:[[roiVolumes objectAtIndex:row] volume]];
//	}
//	else if( [tableColumn isEqualTo:columnRed])
//	{
//		return [NSNumber numberWithFloat:[[roiVolumes objectAtIndex:row] red]];
//	}
//	else if( [tableColumn isEqualTo:columnGreen])
//	{
//		return [NSNumber numberWithFloat:[[roiVolumes objectAtIndex:row] green]];
//	}
//	else if( [tableColumn isEqualTo:columnBlue])
//	{
//		return [NSNumber numberWithFloat:[[roiVolumes objectAtIndex:row] blue]];
//	}
//	else if( [tableColumn isEqualTo:columnOpacity])
//	{
//		return [NSNumber numberWithFloat:[[roiVolumes objectAtIndex:row] opacity]];
//	}
////	else if( [tableColumn isEqualTo:columnColor])
////	{
////		return [[roiVolumes objectAtIndex:row] color];
////	}
//	return 0L;
//}

// delegate method

-(void) Window3DClose:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		NSLog( @"ROIVolumeManager Window3DClose");
		[self close];
	}
}

- (void) windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	NSLog( @"ROIVolumeManager windowWillClose");
	[tableView setDataSource: 0L];
	[controllerAlias setContent: 0L];
	[self release];
}

- (void) dealloc
{
	NSLog( @"ROIVolumeManager dealloc");
	viewer = 0L;
	[roiVolumes release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc];
}

/* Nothing to do
- (void)finalize {
}
*/

- (void) setRoiVolumes: (NSMutableArray*) volumes
{
//	NSLog(@"setRoiVolumes : [volumes count] : %d", [volumes count]);
	[roiVolumes setArray:volumes];
//	NSLog(@"setRoiVolumes : [roiVolumes count] : %d", [roiVolumes count]);
//	NSLog(@"setRoiVolumes : [[self roiVolumes] count] : %d", [[self roiVolumes] count]);
}

- (NSMutableArray*) roiVolumes
{
	return roiVolumes;
}

- (IBAction) showWindow:(id)sender
{
	[super showWindow:sender];
	NSButtonCell *cDisplay = [columnDisplay dataCell];
	[cDisplay setControlSize:NSMiniControlSize];
	[columnDisplay setDataCell:cDisplay];
	
	NSSliderCell *smallSliderCell = [[NSSliderCell alloc] init];
	[smallSliderCell setControlSize:NSMiniControlSize];
	[smallSliderCell setMinValue:0.0];
	[smallSliderCell setMaxValue:1.0];
	
	[columnRed setDataCell:[[smallSliderCell copy] autorelease]];
	[columnGreen setDataCell:[[smallSliderCell copy] autorelease]];
	[columnBlue setDataCell:[[smallSliderCell copy] autorelease]];
	[columnOpacity setDataCell:[[smallSliderCell copy] autorelease]];
	
	[smallSliderCell release];
	
	//[tableView removeTableColumn:columnColor];
}

@end
