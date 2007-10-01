/*=========================================================================
  Program:   OsiriX

  Copyright(c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
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
	int count = 1;
	for (Camera *camera in [self arrangedObjects]) camera.index = count++;
}

- (void)removeObject:(id)sender{
	[super removeObject:sender];
	int count = 1;
	for (Camera *camera in [self arrangedObjects]) camera.index = count++;
}

- (void)removeObjects:(id)sender{
	[super removeObjects:sender];
	int count = 1;
	for (Camera *camera in [self arrangedObjects]) camera.index = count++;
}

- (void)removeObjectAtArrangedObjectIndex:(NSUInteger)index{
	[super removeObjectAtArrangedObjectIndex:(NSUInteger)index];
	int count = 1;
	for (Camera *camera in [self arrangedObjects]) camera.index = count++;
}

- (BOOL)setSelectionIndexes:(NSIndexSet *)indexes{
	BOOL result = [super setSelectionIndexes:(NSIndexSet *)indexes];
	int index = [indexes firstIndex];
	[flyThruController.FTAdapter setCurrentViewToCamera:[[self selectedObjects] objectAtIndex:0]];
	return result;
}
	

- (void) keyDown:(NSEvent *)theEvent
{
	unichar	c = [[theEvent characters] characterAtIndex:0];
	if (c == NSDeleteCharacter)
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
		}
		break;
		
		case 1: //REMOVE
		{
			[self remove:self];
		}
		break;
		
		case 2:	//RESET
		{
			[self removeObjects:[self arrangedObjects]];
			
			flyThruController.hidePlayBox = YES;
			flyThruController.hideExportBox = YES;
		}
		break;
		
		case 3:	//IMPORT
		{
			NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
			[oPanel setAllowsMultipleSelection:NO];
			[oPanel setCanChooseDirectories:NO];
			int result = [oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"xml"]];

			if (result == NSOKButton) 
			{	
				NSDictionary* stepsDictionary = [[NSDictionary alloc] initWithContentsOfFile: [[oPanel filenames] objectAtIndex:0]];
				NSArray *stepsXML = [stepsDictionary valueForKey:@"Step Cameras"];
				NSMutableArray *steps = [NSMutableArray array];
				int count = 1;
				for (NSDictionary *cam in stepsXML) {
					Camera *camera = [[[Camera alloc] initWithDictionary: cam] autorelease];
					camera.index = count++;
					[flyThruController.FTAdapter setCurrentViewToCamera:camera];
					NSImage *im = [flyThruController.FTAdapter getCurrentCameraImage: NO];
					[camera setPreviewImage:im];
					[steps addObject:camera];
				}
				[self setContent:steps];
				[stepsDictionary release];
				
				[flyThruController updateThumbnails];
				
				[self add:self];
				[self remove:self];
			}
		}
		break;
		
		case 4: //SAVE
		{
			NSSavePanel     *panel = [NSSavePanel savePanel];

			[panel setCanSelectHiddenExtension:NO];
			[panel setRequiredFileType:@"xml"];

			if( [panel runModalForDirectory:0L file:@"OsiriX Fly Through"] == NSFileHandlingPanelOKButton)
			{
				NSMutableDictionary *xml;
				xml = [flyThruController.FT exportToXML];
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
	NSLog(@"write rows");
	 // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:FlyThruTableViewDataType] owner:self];
    [pboard setData:data forType:FlyThruTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    // Add code here to validate the drop
    NSLog(@"validate Drop");
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
            row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSLog(@"accept drop");
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:FlyThruTableViewDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	int rowIndex = [rowIndexes firstIndex];
	if (rowIndex  < row)
		row--;
	NSArray *selection = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
	[self removeSelectedObjects:selection];
	[self insertObjects:selection atArrangedObjectIndexes:[NSIndexSet indexSetWithIndex:row]];
	
}


@end
