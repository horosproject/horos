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
	if ([(NSSegmentedControl *)sender selectedSegment] == 1)
		[self remove:sender];
	else
		[self add:sender];
}

- (void)dealloc{
	[[NSUserDefaults standardUserDefaults] setObject:[self content] forKey:@"bodyRegions"];
	[super dealloc];
}


- (IBAction)add: (id)sender{
	NSIndexPath *indexPath = [self selectionIndexPath];	
	NSLog(@"add: %@", [indexPath description]);
	NSMutableArray *array = nil; 
	NSDictionary *dict = nil;
	 switch ([indexPath length]) {
		case 0: //root
		case 1:
			[self addObject:[self newObject]];
			break;
		case 2: 
			dict = [[self content] objectAtIndex:[indexPath indexAtPosition:0]];
			array = [[[dict objectForKey:@"keywords"] mutableCopy] autorelease] ;
			[array addObject:[self newObject]];
			[dict setValue:array forKey:@"keywords"];
			[dict setValue:[NSNumber numberWithInt:[array count]] forKey:@"count"];
			NSLog(@"Body Region: %@", [dict description]);
			// not saved to userDefaults
			break;;
	 }
}


- (IBAction)remove: (id)sender{
	NSLog(@"remove: %@ ", [[self selectionIndexPaths] description]);
	// currently only removes from root array
	[self removeObjectAtArrangedObjectIndexPath:[self selectionIndexPath]];
}


- (void)removeObject:(id)object{
	NSLog(@"removeObject: %@", [object description]);
	[super removeObject:object];
}


- (void)addObject:(id)object{
	NSLog(@"addObject: %@", [object description]);	
	[super addObject:object];
}


- (id)newObject{
		id newObject = [super newObject];
		[newObject setObject:NSLocalizedString(@"NEW", nil) forKey:@"region"];
		[newObject setObject:[NSNumber numberWithInt:0] forKey:@"count"];
		NSLog(@"index Length: %d", [[self selectionIndexPath] length]);
		if ([[self selectionIndexPath] length] < 2){
			id child = [super newObject];
			[child setObject:NSLocalizedString(@"NEW", nil) forKey:@"region"];
			[child setObject:[NSNumber numberWithInt:0] forKey:@"count"];
			[child setObject:[NSNumber numberWithBool:YES] forKey:@"isLeaf"];
			[newObject setObject:[NSNumber numberWithBool:NO] forKey:@"isLeaf"];
			[newObject setObject:[NSArray arrayWithObject:child] forKey:@"keywords"];
			[newObject setObject:[NSNumber numberWithInt:1] forKey:@"count"];
		}
		else
			[newObject setObject:[NSNumber numberWithBool:YES] forKey:@"isLeaf"];
		NSLog(@"new Object: %@", [newObject description]);
		return newObject;
}
	



@end
