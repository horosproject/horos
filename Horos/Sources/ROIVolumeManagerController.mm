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


#import "ROIVolumeManagerController.h"
#import "ROIVolume.h"
#import "Notifications.h"
//#import "ColorWellCell.h"

@implementation ROIVolumeManagerController

- (id) initWithViewer:(Window3DController*) v
{
    self = [super initWithWindowNibName:@"ROIVolumeManager"];
    
	roiVolumes = [[NSMutableArray alloc] initWithCapacity:0];
	[roiVolumes setArray:[v roiVolumes]];
	
	viewer = v;
		
//	[self setRoiVolumes:[v roiVolumes]];
	
	//[[self window] setFrameAutosaveName:@"ROIVolumeManagerWindow"];
	
	// register to notification
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(Window3DClose:)
               name: OsirixWindow3dCloseNotification
             object: nil];
//	[nc addObserver: self
//           selector: @selector(roiListModification:)
//               name: OsirixROIChangeNotification
//             object: nil];
//	[nc addObserver: self
//           selector: @selector(fireUpdate:)
//               name: OsirixRemoveROINotification
//             object: nil];
//	[nc addObserver: self
//           selector: @selector(roiListModification:)
//               name: OsirixDCMUpdateCurrentImageNotification
//             object: nil];
//	[nc addObserver: self
//           selector: @selector(roiListModification:)
//               name: OsirixROISelectedNotification
//             object: nil];
	[tableView setDataSource:self];
	//[tableView setDelegate:self];

	return self;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
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
	else if( [[aTableColumn identifier] isEqualToString:@"texture"])
	{
		[[[roiVolumesController arrangedObjects] objectAtIndex:rowIndex] setTexture:[anObject boolValue]];
		[[viewer view] display];
	}
//	else if( [aTableColumn isEqualTo:columnColor])
//	{
//		[[roiVolumes objectAtIndex:rowIndex] setColor:anObject];
//		[[viewer view] display];
//	}
	[tableView reloadData];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
//	NSLog(@"numberOfRowsInTableView : [[self roiVolumes] count] : %d", [[self roiVolumes] count]);
//	NSLog(@"numberOfRowsInTableView : [roiVolumes count] : %d", [roiVolumes count]);
    return [[self roiVolumes] count];
}

//- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
////NSLog(@"tableView:objectValueForTableColumn:row:");
//	if( viewer == nil) return nil;
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
//	return nil;
//}

// delegate method

-(void) Window3DClose:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		NSLog( @"ROIVolumeManager Window3DClose");
		[[self window] close];
	}
}

- (void) windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	NSLog( @"ROIVolumeManager windowWillClose");
	[tableView setDataSource: nil];
	[controllerAlias setContent: nil];	// To allow the dealloc of MPRController ! otherwise memory leak
    
	[self autorelease];
}

- (void) dealloc
{
	NSLog( @"ROIVolumeManager dealloc");
	viewer = nil;
	[roiVolumes release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc];
}

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
