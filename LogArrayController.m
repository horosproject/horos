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



#import "LogArrayController.h"
#import "browserController.h"

extern BrowserController *browserWindow;


@implementation LogArrayController


- (void)awakeFromNib{
	[self setManagedObjectContext:[browserWindow managedObjectContext]];
	//NSLog(@"query ManagedObjectContext: %@", [[self managedObjectContext] description]);
	[self fetch:nil];
	//NSLog(@"filter Predicate: %@", [[self filterPredicate] description]);
	//NSLog(@"Content: %@", [[self content] description]);
	
}

-(NSManagedObjectContext *)managedObjectContext{
	return [browserWindow managedObjectContext];
}

- (IBAction)nothing:(id)sender{
}

@end
