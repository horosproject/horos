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


#import "DicomDatabase.h"
#import "QueryLogController.h"
#import "browserController.h"

@implementation QueryLogController

- (void)awakeFromNib
{
	[self setManagedObjectContext: [BrowserController.currentBrowser.database managedObjectContext]];
	[self setAutomaticallyPreparesContent: YES];
    
	[self fetch: self];
	
	[self setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO] autorelease]]];
}

- (IBAction)nothing:(id)sender
{

}
@end
