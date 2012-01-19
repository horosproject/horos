/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
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
		NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"DCMTagDictionary")];
		NSString *path = [bundle pathForResource:@"tagDictionary" ofType:@"plist"];
		if( path == nil) NSLog(@"Cannot find tagDictionary");
			sharedTagDictionary  = [[DCMTagDictionary alloc] initWithContentsOfFile:path];
		
//		NSLog( @"%@", sharedTagDictionary);
		
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
