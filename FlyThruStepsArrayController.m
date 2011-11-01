/*=========================================================================
  Program:   OsiriX

  Copyright(c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "FlyThruStepsArrayController.h"
#import "FlyThruController.h"

#define FlyThruTableViewDataType @"FlyThruTableViewDataType"

@implementation FlyThruStepsArrayController



- (void)addObject:(id)object {
	// add the current Camera from flythuController
	[super addObject:flyThruController.currentCamera];
	[self resetCameraIndexes];
	
	[tableview scrollRowToVisible: [tableview selectedRow]];
}

- (void)addObjects:(NSArray *)objects{
	[super addObjects:objects];
	[self resetCameraIndexes];
	
	[tableview scrollRowToVisible: [tableview selectedRow]];
}
	

- (void)removeObject:(id)sender{
	[super removeObject:sender];
	[self resetCameraIndexes];
}

- (void)removeObjects:(id)sender{
	[super removeObjects:sender];
	[self resetCameraIndexes];
}

- (void)removeObjectAtArrangedObjectIndex:(NSUInteger)index{
	[super removeObjectAtArrangedObjectIndex:(NSUInteger)index];
	[self resetCameraIndexes];
}

- (BOOL)setSelectionIndexes:(NSIndexSet *)indexes{
	BOOL result = [super setSelectionIndexes:(NSIndexSet *)indexes];
	NSUInteger index = [indexes firstIndex];
	if( index == NSNotFound) return NO;
	[flyThruController.FTAdapter setCurrentViewToCamera:[[self selectedObjects] objectAtIndex:0]];
	return result;
}
	

- (void) keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
	unichar	c = [[theEvent characters] characterAtIndex:0];
	if (c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
	{
		[self remove:self];
	}

}

- (void) flyThruTag:(int) x
{
	switch( x)
	{
		case 0:	// ADD
		{
			[self add:self];
			
			flyThruController.hidePlayBox = YES;
			flyThruController.hideExportBox = YES;

//			[self setSelectedObjects: [NSArray arrayWithObject:[[self arrangedObjects] lastObject]]];
//			if([tableview selectedRow]>=0)[tableview scrollRowToVisible:[tableview selectedRow]];
		}
		break;
		
		case 1: //REMOVE
		{
			[self remove:self];
		}
		break;
		
		case 2:	//RESET
		{
			[self resetCameras:self];
		}
		break;
		
		case 3:	//IMPORT
		{
			NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
			[oPanel setAllowsMultipleSelection:NO];
			[oPanel setCanChooseDirectories:NO];
			int result = [oPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"xml"]];

			if (result == NSOKButton) 
			{	
				[self resetCameras:self];
				NSDictionary* stepsDictionary = [[NSDictionary alloc] initWithContentsOfFile: [[oPanel filenames] objectAtIndex:0]];
				NSArray *stepsXML = [stepsDictionary valueForKey:@"Step Cameras"];
				int count = 1;
				for (NSDictionary *cam in stepsXML) {
					Camera *camera = [[[Camera alloc] initWithDictionary: cam] autorelease];
					camera.index = count++;
					[flyThruController.FTAdapter setCurrentViewToCamera:camera];
					NSImage *im = [flyThruController.FTAdapter getCurrentCameraImage: NO];
					[camera setPreviewImage:im];
					[self addObject:camera];
				}
				[stepsDictionary release];
				[self resetCameraIndexes];
			}
		}
		break;
		
		case 4: //SAVE
		{
			NSSavePanel     *panel = [NSSavePanel savePanel];

			[panel setCanSelectHiddenExtension:NO];
			[panel setRequiredFileType:@"xml"];

			if( [panel runModalForDirectory:nil file:@"OsiriX Fly Through"] == NSFileHandlingPanelOKButton)
			{
				NSMutableDictionary *xml;
				xml = [flyThruController.flyThru exportToXML];
				[xml writeToFile:[panel filename] atomically: TRUE];
			}
		}
		break;
	}
}

- (IBAction) flyThruButton:(id) sender
{
	[self flyThruTag: [sender selectedSegment]];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{

	 // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:FlyThruTableViewDataType] owner:self];
    [pboard setData:data forType:FlyThruTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
  
	// only allow drops within the table

   if ([tv isEqual:tableview])
		return NSDragOperationMove;
		
	return NSDragOperationNone;
	
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{

    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:FlyThruTableViewDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	int rowIndex = [rowIndexes firstIndex];
	if (rowIndex  < row)
		row--;
	id object = [[[self arrangedObjects] objectAtIndex: rowIndex] retain];
	[self removeObjectsAtArrangedObjectIndexes:rowIndexes];
	[self insertObject:object atArrangedObjectIndex:row];	
	[self resetCameraIndexes];
	[object release];
	return YES;
}

- (void) resetCameraIndexes{
 	int count = 1;
	for (Camera *camera in [self arrangedObjects]) camera.index = count++;
}

- (IBAction)updateCamera:(id)sender{
	NSUInteger index = [self selectionIndex];
	if(index==NSNotFound) return;
	[self remove:sender];
	[self insertObject:flyThruController.currentCamera atArrangedObjectIndex:index];
	[self resetCameraIndexes];
}

- (IBAction)resetCameras:(id)sender{
	[self removeObjects:[self arrangedObjects]];
	
	flyThruController.hidePlayBox = YES;
	flyThruController.hideExportBox = YES;
}


@end
