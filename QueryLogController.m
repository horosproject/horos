//
//  QueryLogController.m
//  OsiriX
//
//  Created by Lance Pysher on 8/16/05.
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


#import "QueryLogController.h"
#import "browserController.h"

extern BrowserController *browserWindow;


@implementation QueryLogController

- (void)awakeFromNib{
	[self setManagedObjectContext:[browserWindow managedObjectContext]];
	//NSLog(@"filter Predicate: %@", [[self filterPredicate] description]);
	[self fetch:nil];
	//NSLog(@"Content: %@", [[self content] description]);
	
	[self setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO] autorelease]]];
}

-(NSManagedObjectContext *)managedObjectContext{
	return [browserWindow managedObjectContext];
}

- (IBAction)nothing:(id)sender{
//	[self fetch:sender];
//	NSLog(@"Content: %@", [[self content] description]);
}


@end
