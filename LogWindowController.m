/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "LogWindowController.h"
#import "browserController.h"
#import "DicomDatabase.h"

@implementation LogWindowController

- (IBAction) export:(id) sender
{
	NSArray *a = nil;
	NSString *filename = nil;
	
	switch( [sender tag])
	{
		case 1: a = [receive arrangedObjects]; filename = @"ReceiveLog.csv"; break;
		case 2: a = [send arrangedObjects]; filename = @"SendLog.csv"; break;
		case 3: a = [move arrangedObjects]; filename = @"MoveLog.csv"; break;
		case 4: a = [web arrangedObjects]; filename = @"WebLog.csv"; break;
	}
	
	NSMutableString *csv = [NSMutableString string];
	
	NSArray *logEntries = [[[[BrowserController.currentBrowser.database.managedObjectModel entitiesByName] objectForKey:@"LogEntry"] attributesByName] allKeys];
	
	// HEADER
	NSMutableString *line = [NSMutableString string];
	for( NSString *name in logEntries)
	{
		[line appendString: name];
		[line appendString: @","];
	}
	[line deleteCharactersInRange: NSMakeRange( [line length]-1, 1)];
	[csv appendString: line];
	[csv appendString: @"\n"];
	
	for( NSManagedObject *o in a)
	{
		line = [NSMutableString string];
		for( NSString *name in logEntries)
		{
			if( [o valueForKey: name])
			{
				if( [[o valueForKey: name] isKindOfClass: [NSDate class]])
					[line appendString: [[BrowserController DateTimeFormat: [o valueForKey: name]] stringByReplacingOccurrencesOfString: @"," withString: @" "]];
				else
					[line appendString: [[[o valueForKey: name] description] stringByReplacingOccurrencesOfString: @"," withString: @" "]];
			}
			else
				[line appendString: @"void"];
				
			[line appendString: @","];
		}
		[line deleteCharactersInRange: NSMakeRange( [line length]-1, 1)];
		
		[csv appendString: line];
		[csv appendString: @"\n"];
	}
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setRequiredFileType:@"csv"];
	
	if([savePanel runModalForDirectory: nil file: filename] == NSFileHandlingPanelOKButton)
	{
		[csv writeToURL: [savePanel URL] atomically: YES];
	}
}

-(id) init
{
	return  [super initWithWindowNibName:@"LogWindow"];
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
		if( NSRunInformationalAlertPanel( NSLocalizedString( @"Network Logs", nil), NSLocalizedString( @"Network Logs are currently off. Do you want to activate them?\r\rYou can activate or de-activate them in the Preferences - Listener window.", nil), NSLocalizedString( @"Activate", nil), NSLocalizedString( @"Cancel", nil), nil) == 1)
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NETWORKLOGS"];
			[[BrowserController currentBrowser] setNetworkLogs];
		}
	}
}

@end
