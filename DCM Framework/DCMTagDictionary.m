//
//  DCMTagDictionary.m
//  OsiriX
//
//  Created by Lance Pysher on Wed Jun 09 2004.

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

#import "DCMTagDictionary.h"
#import "DCM.h"

static DCMTagDictionary *sharedTagDictionary; 

@implementation DCMTagDictionary

+(id)sharedTagDictionary{		
	if (!sharedTagDictionary) {
		//NSDate *date = [NSDate date];
		NSBundle *bundle;
		bundle  = [NSBundle bundleForClass:NSClassFromString(@"DCMTagDictionary")];

		NSString *path = [bundle pathForResource:@"tagDictionary" ofType:@"plist"];
		if( path == 0L) NSLog(@"Cannot find tagDictionary");
			sharedTagDictionary  = [[NSDictionary alloc] initWithContentsOfFile:path];
				
		//NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:date];
	}
	
//	NSEnumerator *enumerator = [sharedTagDictionary objectEnumerator];	THIS LOOP IS EXTREMELY SLOW!
//	NSDictionary *dict;
//	while (dict = [enumerator nextObject]){
//		if (![dict objectForKey:@"VR"])
//			NSLog([dict description]);
//	}
	
	return sharedTagDictionary;
	
}

- (void) dealloc {
	[super dealloc];
}

@end
