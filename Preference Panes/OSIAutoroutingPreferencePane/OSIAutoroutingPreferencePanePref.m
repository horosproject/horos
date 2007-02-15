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


#import "OSIAutoroutingPreferencePanePref.h"

@implementation OSIAutoroutingPreferencePanePref

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
	
	if( aView == _authView) return;
	
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }

	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

- (void) enableControls: (BOOL) val
{
	[self checkView: [self mainView] :val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.autorouting"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];
	
	routesArray = [[[defaults arrayForKey:@"AUTOROUTINGDICTIONARY"] mutableCopy] retain];
	if (routesArray == 0L) routesArray = [[NSMutableArray alloc] initWithCapacity: 0];
	
	int i;
	for( i = 0 ; i < [routesArray count] ; i++)
	{
		NSMutableDictionary	*newDict = [NSMutableDictionary dictionaryWithDictionary: [routesArray objectAtIndex: i]];
		[routesArray replaceObjectAtIndex: i withObject:newDict];
		
		if( [newDict valueForKey:@"activated"] == 0)
		{
			[newDict setValue: [NSNumber numberWithBool: YES] forKey:@"activated"];
		}
	}
	
	[routesTable reloadData];
	
	[routesTable setDelegate:self];
	[routesTable setDoubleAction:@selector( editRoute:)];
	[routesTable setTarget: self];
	
	[autoroutingActivated setState: [defaults boolForKey:@"AUTOROUTINGACTIVATED"]];
	
	NSArray	*serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	for( i = 0; i < [routesArray count]; i++)
	{
		NSLog( [[routesArray objectAtIndex:i] valueForKey:@"server"]);
		
		int		x;
		BOOL	found = NO;
		for( x = 0; x < [serversArray count]; x++)
		{
			if( [[[serversArray objectAtIndex: x] valueForKey:@"Description"] isEqualToString: [[routesArray objectAtIndex:i] valueForKey:@"server"]]) found = YES;
		}
		
		if( found == NO)
			NSRunCriticalAlertPanel(NSLocalizedString(@"Unknown Server",nil), [NSString stringWithFormat:NSLocalizedString( @"This server doesn't exist in the Locations list: %@",nil), [[routesArray objectAtIndex: i] valueForKey:@"server"]],NSLocalizedString( @"OK",nil), nil, nil);
	}
}

-(void) willUnselect
{
	[[NSUserDefaults standardUserDefaults] setObject: routesArray forKey:@"AUTOROUTINGDICTIONARY"];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOROUTINGACTIVATED"])
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey:@"INC"]+1  forKey:@"INC"];
	}
}

- (void)dealloc
{
	NSLog(@"dealloc OSIAutoroutingPreferencePanePref");
	
	[routesArray release];
	
	[super dealloc];
}

- (IBAction)setActivated:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"AUTOROUTINGACTIVATED"];
}

- (IBAction) syntaxHelpButtons:(id) sender
{
	if( [sender tag] == 0)
	{
		[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"]];
	}
	
	if( [sender tag] == 1)
	{
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
	}
}

static BOOL newRouteMode = NO;

- (IBAction) endNewRoute:(id) sender
{
	if( [sender tag] == 1)
	{
		NSArray	*serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
		
		[routesArray replaceObjectAtIndex: [routesTable selectedRow] withObject: [NSDictionary dictionaryWithObjectsAndKeys: [newName stringValue], @"name", [NSNumber numberWithBool:YES], @"activated", [newDescription stringValue], @"description", [newFilter stringValue], @"filter", [[serversArray objectAtIndex: [serverPopup indexOfSelectedItem]] objectForKey:@"Description"], @"server", 0L]];
	}
	else
	{
		if( newRouteMode)
		{
			[routesArray removeObjectAtIndex: [routesTable selectedRow]];
		}
	}
	
	[routesTable reloadData];
	[newRoute orderOut:sender];
	[NSApp endSheet: newRoute returnCode:[sender tag]];
}

- (IBAction) selectServer:(id) sender
{
	NSArray	*serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	int i = [sender indexOfSelectedItem];
	
	[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[serversArray objectAtIndex: i] objectForKey:@"Address"], [[serversArray objectAtIndex: i] objectForKey:@"Port"]]];
}

- (IBAction) editRoute:(id) sender
{
	newRouteMode = NO;
	
	NSArray	*serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	if( [serversArray count] == 0)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"New Route",nil),NSLocalizedString( @"No destination servers exist. Create at least one destination in the Locations preferences.",nil),NSLocalizedString( @"OK",nil), nil, nil);
	}
	else
	{
		NSDictionary	*selectedRoute = [routesArray objectAtIndex: [routesTable selectedRow]];
		
		if( selectedRoute)
		{
			int i;
			[serverPopup removeItemAtIndex: 0];
			for( i = 0; i < [serversArray count]; i++)
			{
				NSString	*name = [NSString stringWithFormat:@"%@ - %@", [[serversArray objectAtIndex: i] objectForKey:@"AETitle"], [[serversArray objectAtIndex: i] objectForKey:@"Description"]];
			
				[serverPopup addItemWithTitle: name];
			}
			
			[newName setStringValue: [selectedRoute valueForKey: @"name"]];
			[newDescription setStringValue: [selectedRoute valueForKey: @"description"]];
			[newFilter setStringValue: [selectedRoute valueForKey: @"filter"]];
			
			for( i = 0; i < [serversArray count]; i++)
			{
				if ([[[serversArray objectAtIndex: i] objectForKey:@"Description"] isEqualToString: [selectedRoute valueForKey: @"server"]]) 
				{
					[serverPopup selectItemAtIndex: i];
				}
			}
			
			[self selectServer: serverPopup];
			
			[NSApp beginSheet: newRoute modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		}
	}
}

- (IBAction) newRoute:(id) sender
{
	NSArray	*serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	[routesArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: @"new route", @"name", @"", @"description", @"(modality like[c] \"CT\")", @"filter", [[serversArray objectAtIndex: 0] objectForKey:@"Description"], @"server", 0L]];
	
	[routesTable reloadData];
	
	[routesTable selectRow: [routesArray count]-1 byExtendingSelection: NO];
	
	[self editRoute: self];
	
	newRouteMode = YES;
}

- (void) deleteSelectedRow:(id)sender
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState)
	{
		if( [sender tag] == 0)
		{
			[routesArray removeObjectAtIndex:[routesTable selectedRow]];
			[routesTable reloadData];
		}
	}
}


- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( [aTableView tag] == 0)	return [routesArray count];
	
	return 0;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if( [tableView tag] == 0)
	{
		[routesArray sortUsingDescriptors: [routesTable sortDescriptors]];
		[routesTable reloadData];
	}
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	NSMutableDictionary *theRecord;
	
	if( [aTableView tag] == 0)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [routesArray count]);
		
		theRecord = [routesArray objectAtIndex:rowIndex];
		
		return [theRecord objectForKey:[aTableColumn identifier]];
	}
	
	return 0L;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [[aTableColumn identifier] isEqualToString:@"activated"])
		[[routesArray objectAtIndex:rowIndex] setValue:anObject forKey: [aTableColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) return YES;
	else return NO;
}
@end
