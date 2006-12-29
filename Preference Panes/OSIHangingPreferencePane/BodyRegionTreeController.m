//
//  BodyRegionTreeController.m
//  OSIHangingPreferencePane
//
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


#import "BodyRegionTreeController.h"


@implementation BodyRegionTreeController

- (IBAction) addRemoveAction: (id)sender{
	NSLog(@"add or Remove Object");
	if ([(NSSegmentedControl *)sender selectedSegment] == 1)
		[self remove:sender];
	else
		[self add:sender];
}

- (IBAction)add: (id)sender{
	NSIndexPath *indexPath = [self selectionIndexPath];
	NSLog(@"path length: %d", [indexPath  length]);
	
	unsigned int *indexes;
	 [indexPath getIndexes:indexes];
	 
	// if ([indexPath length] > 1) {
	 /*
		int position = [indexPath length] - 1;
		int index = indexes[position]++;
		NSIndexPath *baseIndex = [indexPath indexPathByRemovingLastIndex];
		NSIndexPath *newIndex = [baseIndex indexPathByAddingIndex:index];
		[self insertObject:[self newObject] atArrangedObjectIndexPath:newIndex];
	*/
//	}
//	 else
//	if ([indexPath  length] < 1)
//		[self addObject:[self newObject]];
}

- (IBAction)remove: (id)sender{
	NSLog(@"remove: %@ ", [[self selectionIndexPaths] description]);
	[self removeObjectsAtArrangedObjectIndexPaths:[self selectionIndexPaths]];
}

/*
- (void)removeObject:(id)object{
	NSLog(@"removeObject: %@", [object description]);
	[super removeObject:object];
}
*/

- (void)addObject:(id)object{
	NSLog(@"addObject: %@", [object description]);	
	[super addObject:object];
}


- (id)newObject{
	if ([[self selectionIndexPath] length] == 0) {
		id newObject = [super newObject];
		[newObject setObject:NSLocalizedString(@"NEW", nil) forKey:@"region"];
		[newObject setObject:[NSNumber numberWithInt:0] forKey:@"count"];
		NSLog(@"index Length: %d", [[self selectionIndexPath] length]);
		if ([[self selectionIndexPath] length] < 2){
			[newObject setObject:[NSNumber numberWithBool:NO] forKey:@"isLeaf"];
			[newObject setObject:[NSArray arrayWithObject:NSLocalizedString(@"NEW", nil)] forKey:@"keywords"];
		}
		else
			[newObject setObject:[NSNumber numberWithBool:YES] forKey:@"isLeaf"];
		NSLog(@"new Object: %@", [newObject description]);
		return newObject;
	}
	return nil;
}
	



@end
