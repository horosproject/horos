//
//  DCMTagForNameDictionary.m
//  OsiriX
//
//  Created by Lance Pysher on Wed Jun 09 2004.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMTagForNameDictionary.h"
#import "DCM.h"

static DCMTagForNameDictionary *sharedTagForNameDictionary; 

@implementation DCMTagForNameDictionary

+(id)sharedTagForNameDictionary{
	if (!sharedTagForNameDictionary) {
	 NSBundle *bundle;
	if (DCMFramework_compile)
		bundle  = [NSBundle bundleForClass:NSClassFromString(@"DCMTagForNameDictionary")];
	else
		bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource:@"nameDictionary" ofType:@"plist"];
	if( path == 0L) NSLog(@"Cannot find nameDictionary");
		sharedTagForNameDictionary = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
		
	if (DEBUG)
		NSLog(@"shared name dictionary; %@", [sharedTagForNameDictionary description]);
	}
	return sharedTagForNameDictionary;
}

- (void) dealloc {
	[sharedTagForNameDictionary release];
	[super dealloc];
}


@end
