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

#import "IChatTheatreHelpWindowController.h"
#import "IChatTheatreDelegate.h"

@implementation IChatTheatreHelpWindowController

- (void)windowDidLoad;
{
	[super windowDidLoad];
	
	NSString *source = [NSString stringWithFormat:@"iChatTheatre-%@", [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex: 0]];
	
	NSString *path = [[NSBundle mainBundle] pathForResource: source ofType:@"html"];
	
	if( path == nil) path = [[NSBundle mainBundle] pathForResource:@"iChatTheatre-English" ofType:@"html"];
	
	[[[IChatTheatreDelegate sharedDelegate] web] setMainFrameURL:path];
	
}

@end
