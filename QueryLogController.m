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



#import "QueryLogController.h"
#import "browserController.h"

@implementation QueryLogController

- (void)awakeFromNib
{
	[self setManagedObjectContext: [[BrowserController currentBrowser] managedObjectContext]];
	[self fetch:nil];
	
	[self setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO] autorelease]]];
}

-(NSManagedObjectContext *)managedObjectContext
{
	return [[BrowserController currentBrowser] managedObjectContext];
}

- (IBAction)nothing:(id)sender
{

}

@end
