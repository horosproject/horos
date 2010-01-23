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



#import "QueryLogController.h"
#import "browserController.h"

@implementation QueryLogController

- (void)awakeFromNib
{
	[self setManagedObjectContext: [[BrowserController currentBrowser] managedObjectContext]];
	[self setAutomaticallyPreparesContent: YES];
	
	[self fetch: self];
	
	[self setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO] autorelease]]];
	
	
//	[self setEntityName: @"LogEntry"];
//	[self setFilterPredicate: [NSPredicate predicateWithValue:YES]];
//	[self fetch: self];
//	
//	
//	NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
//	[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"LogEntry"]];
//	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
//	
//	NSError *error = nil;
//	NSArray *logArray = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest:dbRequest error: &error];
//	
//	if( error)
//		NSLog( @"%@", error);
//	[self addObject: logArray];
//	NSLog( @"%@", [self arrangedObjects]);
}

-(NSManagedObjectContext *)managedObjectContext
{
	return [[BrowserController currentBrowser] managedObjectContext];
}

- (IBAction)nothing:(id)sender
{

}

@end
