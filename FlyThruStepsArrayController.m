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

- (void) keyDown:(NSEvent *)theEvent
{
	unichar	c = [[theEvent characters] characterAtIndex:0];
	if (c == NSDeleteCharacter)
	{
		[self remove:self];
	}
	else
	{
		[super keyDown:theEvent];
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
				[flyThruController.FT setFromDictionary: stepsDictionary];
				[stepsDictionary release];
				
				[flyThruController updateThumbnails];
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


@end
