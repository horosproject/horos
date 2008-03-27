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



#import "LogWindowController.h"
#import "browserController.h"


@implementation LogWindowController

-(id) init
{
	return  [super initWithWindowNibName:@"LogWindow"];
}

- (NSManagedObjectContext *)managedObjectContext{
}
	
-(void) awakeFromNib
{
	[[self window] setFrameAutosaveName:@"LogWindow"];
}

- (void) dealloc
{
	NSLog( @"LogWindowController dealloc");
	
	[super dealloc];
}


-(IBAction) showWindow:(id) sender
{
	[super showWindow: sender];
	
	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO)
	{
		if( NSRunInformationalAlertPanel(@"Network Logs", @"Network Logs are currently off. Do you want to activate them?\r\rYou can activate or de-activate them in the Preferences - Listener window.", @"Activate", @"Cancel", 0L) == 1)
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NETWORKLOGS"];
			[[BrowserController currentBrowser] setNetworkLogs];
		}
	}
}

@end
