//
//  LayoutArrayController.m
//  OsiriX
//
//  Created by Lance Pysher on 1/10/07.

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


#import "LayoutArrayController.h"
#import "WindowLayoutManager.h"
#import "OSIWindowController.h"
#import "browserController.h"
#import "ViewerController.h"
#import "VRController.h"
#import "WindowLayoutManager.h"
#import "VRControllerVPRO.h"
#import "SRController.h"
#import "EndoscopyViewer.h"
#import "SeriesView.h"


@implementation LayoutArrayController

- (IBAction)addDeleteAction:( id)sender{
	if ([sender selectedSegment] == 0)
		[self add:sender];
	else
		[self remove:sender];
}

- (void)add:(id)sender{
	[self addObject:[self newObject]];
}


- (id)newObject{
	id newObject = [super newObject];
	[newObject setValue:[NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Layout", nil), [[self content] count] + 1] forKey:@"name"];
	BOOL hasComparison = NO;
	NSString *comparisonModality = NSLocalizedString(@"None", nil);
	NSEnumerator *enumerator = [[[WindowLayoutManager sharedWindowLayoutManager] viewers] objectEnumerator];
	id controller;
	//see all viewers have the same Study. If not we have a comparison
	while (controller = [enumerator nextObject]) {
		if (![[controller currentStudy] isEqual:[[WindowLayoutManager sharedWindowLayoutManager] currentStudy]]) {
			hasComparison = YES;
			if ([[[controller currentStudy] valueForKey:@"studyName"] isEqualToString:
			[[[WindowLayoutManager sharedWindowLayoutManager] currentStudy] valueForKey:@"studyName"]])
				comparisonModality = NSLocalizedString(@"Exact Match", nil);
			else
				comparisonModality = NSLocalizedString(@"Any", nil);
		}
	}
	
	[newObject setValue:[NSNumber numberWithBool:hasComparison] forKey: @"hasComparison"];
	[newObject setValue:[self viewers] forKey:@"viewers"];
	[newObject setValue:comparisonModality forKey:@"comparisonModality"];
	return newObject;
}


- (NSArray *)viewers{
	NSMutableArray *viewersArray = [NSMutableArray array];
	NSEnumerator *enumerator = [[[WindowLayoutManager sharedWindowLayoutManager] viewers] objectEnumerator];
	id controller;
	while (controller = [enumerator nextObject]) {
			/*
			 Each Series needs ViewerClass
			 series description (name)
			 ww/wl
			 CLUT
			 Window Frame
			 Screen Number
			 fusion
			 ImageTiles layout
			 rotation
			 zoom	
			*/
			
	
		NSMutableDictionary *seriesInfo = [NSMutableDictionary dictionary];
		NSWindow *window = [controller window];
		NSString *frame  = [window stringWithSavedFrame];
		[seriesInfo setObject:frame forKey:@"windowFrame"];
		NSScreen *screen = [window screen];				
		int screenNumber = [[NSScreen screens] indexOfObject:screen];
		[seriesInfo setObject:[NSNumber numberWithInt:screenNumber] forKey:@"screenNumber"];
		id series = [controller currentSeries];
		
		if ([[controller currentStudy] isEqual:[[WindowLayoutManager sharedWindowLayoutManager] currentStudy]]) {
			[seriesInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isComparison"];
		}
		else {
			[seriesInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isComparison"];
		}
			
		if ([series valueForKey:@"name"])
			[seriesInfo setObject:[series valueForKey:@"name"] forKey:@"seriesDescription"];
		else 
			[seriesInfo setObject:NSLocalizedString(@"unnamed", nil) forKey:@"seriesDescription"];
			
		if ([series valueForKey:@"id"])
			[seriesInfo setObject:[series valueForKey:@"id"] forKey:@"seriesNumber"];
			
		if ([series valueForKey:@"seriesDescription"])
			[seriesInfo setObject:[series valueForKey:@"seriesDescription"] forKey:@"protocolName"];
		else
			[seriesInfo setObject:NSLocalizedString(@"unnamed", nil) forKey:@"protocolName"];
	

		// Not supported by OrthogonalMPRPETCTViewer
		if (!([controller isKindOfClass:[OrthogonalMPRPETCTViewer class]]  || [controller isKindOfClass:[SRController class]])) {
			// WW/wl presets only work well with CT
			if ([[[controller currentStudy] valueForKey:@"modality"] isEqualToString:@"CT"]) {
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller curWW]] forKey:@"ww"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller curWL]] forKey:@"wl"];
			}
			[seriesInfo setObject:[controller curCLUTMenu] forKey:@"CLUTName"];
		}
		
		if ([controller isKindOfClass:[SRController class]]) {
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller firstSurface]] forKey:@"firstSurface"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller secondSurface]] forKey:@"secondSurface"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller resolution]] forKey:@"resolution"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller firstTransparency]] forKey:@"firstTransparency"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller secondTransparency]] forKey:@"secondTransparency"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller decimate]] forKey:@"decimate"];
			[seriesInfo setObject:[NSNumber numberWithInt:[controller smooth]] forKey:@"smooth"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller shouldDecimate]] forKey:@"shouldDecimate"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller shouldSmooth]] forKey:@"shouldSmooth"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller useFirstSurface]] forKey:@"useFirstSurface"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller useSecondSurface]] forKey:@"useSecondSurface"];
			[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller firstColor]] forKey:@"firstColor"];
			[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller secondColor]] forKey:@"secondColor"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller shouldRenderFusion]] forKey:@"shouldRenderFusion"];
			
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionFirstSurface]] forKey:@"fusionFirstSurface"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionSecondSurface]] forKey:@"fusionSecondSurface"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionResolution]] forKey:@"fusionResolution"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionFirstTransparency]] forKey:@"fusionFirstTransparency"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionSecondTransparency]] forKey:@"fusionSecondTransparency"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionDecimate]] forKey:@"fusionDecimate"];
			[seriesInfo setObject:[NSNumber numberWithInt:[controller fusionSmooth]] forKey:@"fusionSmooth"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionShouldDecimate]] forKey:@"fusionShouldDecimate"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionShouldSmooth]] forKey:@"fuiosnShouldSmooth"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionUseFirstSurface]] forKey:@"fusionUseFirstSurface"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionUseSecondSurface]] forKey:@"fusionUseSecondSurface"];
			[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller fusionFirstColor]] forKey:@"fusionFirstColor"];
			[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller fusionSecondColor]] forKey:@"fusionSecondColor"];

		}
		
		if ([controller isKindOfClass:[ViewerController class]]) {
			// WW/wl presets only work well with CT
			if ([[[controller currentStudy] valueForKey:@"modality"] isEqualToString:@"CT"])
				[seriesInfo setObject:[controller curWLWWMenu] forKey:@"wwwlMenuItem"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller rotation]] forKey:@"rotation"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller scaleValue]] forKey:@"zoom"];
			[seriesInfo setObject:[NSNumber numberWithInt:[[controller seriesView] imageRows]] forKey:@"imageRows"];
			[seriesInfo setObject:[NSNumber numberWithInt:[[controller seriesView] imageColumns]] forKey:@"imageColumns"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller xFlipped]] forKey:@"xFlipped"];
			[seriesInfo setObject:[NSNumber numberWithBool:[controller yFlipped]] forKey:@"yFlipped"];
		}
		
		//Save Viewer Class
		[seriesInfo setObject:NSStringFromClass([controller class]) forKey:@"Viewer Class"];
		
		// MIP vs VP fpr Volume Rendering
		if ([controller isKindOfClass:[VRController class]] || [controller isKindOfClass:[VRPROController class]] )
			[seriesInfo setObject:[(VRController  *)controller renderingMode] forKey:@"mode"];
			
		[seriesInfo setObject:[NSNumber numberWithBool:[window isKeyWindow]] forKey:@"isKeyWindow"];
		
		// Have blending.  Get Series Description for blending
		
		if ([controller isKindOfClass:[ViewerController class]] && [controller blendingController]) {
			id blendingSeries = [[controller blendingController] currentSeries];
			[seriesInfo setObject:[blendingSeries valueForKey:@"name"] forKey:@"blendingSeriesDescription"];
			[seriesInfo setObject:[blendingSeries valueForKey:@"id"] forKey:@"blendingSeriesNumber"];	
			[seriesInfo setObject:[NSNumber numberWithInt:[controller blendingType]] forKey:@"blendingType"];					
		}

		[viewersArray addObject:seriesInfo];

	}	
	return viewersArray;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info 
            row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:@"LayoutDraggingType"];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];
	id dragObject = [[[self arrangedObjects] objectAtIndex:dragRow] retain];
	[self removeObject:dragObject];
	[self insertObject:dragObject  atArrangedObjectIndex:row];
	[dragObject release];
	return YES;
    // Move the specified row to its new location...
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op 
{
    // Add code here to validate the drop
    return NSDragOperationEvery;    
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:@"LayoutDraggingType"] owner:self];
    [pboard setData:data forType:@"LayoutDraggingType"];
    return YES;
}

@end
