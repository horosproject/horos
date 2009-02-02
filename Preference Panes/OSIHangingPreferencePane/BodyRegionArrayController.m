/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "BodyRegionArrayController.h"


@implementation BodyRegionArrayController

- (void)setContent:(id)content{
	NSMutableArray *newContent = [NSMutableArray array];
	NSDictionary *dict;
	NSEnumerator *enumerator = [content objectEnumerator];
	while (dict = [enumerator nextObject]){
		NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
		NSEnumerator *enumerator2 = [[newDict objectForKey:@"keywords"] objectEnumerator];
		NSDictionary *keywords;
		NSMutableArray *childArray = [NSMutableArray array];
		while (keywords = [enumerator2 nextObject]) {
			NSMutableDictionary *newKeywords  = [NSMutableDictionary dictionaryWithDictionary:keywords];
			[childArray addObject:newKeywords];
		}
		[newDict setObject:childArray forKey:@"keywords"];		
		[newContent addObject:newDict];
	}
	[super setContent:newContent];
}

- (IBAction)addOrRemove:(id)sender{
	if ([sender selectedSegment] == 0)
		[self add:sender];
	else
		[self remove:sender];
}
	

@end
