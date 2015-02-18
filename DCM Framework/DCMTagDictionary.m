/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
