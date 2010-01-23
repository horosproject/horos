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

#import "DCMTagForNameDictionary.h"
#import "DCM.h"

static DCMTagForNameDictionary *sharedTagForNameDictionary; 

@implementation DCMTagForNameDictionary

+(id)sharedTagForNameDictionary
{
	if (!sharedTagForNameDictionary)
	{
		NSBundle *bundle;
		if (DCMFramework_compile)
			bundle  = [NSBundle bundleForClass:NSClassFromString(@"DCMTagForNameDictionary")];
		else
			bundle = [NSBundle mainBundle];
			
		NSString *path = [bundle pathForResource:@"nameDictionary" ofType:@"plist"];
		if( path == nil)
		{
			
		}
		
		sharedTagForNameDictionary = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
	}
	return sharedTagForNameDictionary;
}

- (void) dealloc {
	[sharedTagForNameDictionary release];
	[super dealloc];
}


@end
