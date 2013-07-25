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

#import <OsiriX/DCMObject.h>
#import "OSIAutoroutingPreferencePanePref.h"
#import <OsiriXAPI/NSPreferencePane+OsiriX.h>
#import <OsiriXAPI/AppController.h>

@implementation OSIAutoroutingPreferencePanePref

@synthesize filterType;

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIAutoroutingPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	routesArray = [[defaults arrayForKey:@"AUTOROUTINGDICTIONARY"] mutableCopy];
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
	[routesTable setDoubleAction:@selector(editRoute:)];
	[routesTable setTarget: self];
	
	[serversArray release];
	serversArray = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"] retain];
	
	for( i = 0; i < [routesArray count]; i++)
	{
		NSLog( @"%@", [[routesArray objectAtIndex:i] valueForKey:@"server"]);
		
		int		x;
		BOOL	found = NO;
		for( x = 0; x < [serversArray count]; x++)
		{
			if( [[[serversArray objectAtIndex: x] valueForKey:@"Activated"] boolValue] && [[[serversArray objectAtIndex: x] valueForKey:@"Description"] isEqualToString: [[routesArray objectAtIndex:i] valueForKey:@"server"]]) found = YES;
		}
		
		if( found == NO)
			NSRunCriticalAlertPanel(NSLocalizedString(@"Unknown Server", nil), [NSString stringWithFormat:NSLocalizedString( @"This server doesn't exist in the Locations list: %@", nil), [[routesArray objectAtIndex: i] valueForKey:@"server"]],NSLocalizedString( @"OK", nil), nil, nil);
	}
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];

	[[NSUserDefaults standardUserDefaults] setObject: routesArray forKey:@"AUTOROUTINGDICTIONARY"];
}

- (void)dealloc
{
	NSLog(@"dealloc OSIAutoroutingPreferencePanePref");
	
	[routesArray release];
	[serversArray release];
	
	[super dealloc];
}

- (IBAction) syntaxHelpButtons:(id) sender
{
	if( [sender tag] == 0)
	{
        [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/OsiriXTables.pdf" error:nil];
        [[NSFileManager defaultManager] copyItemAtPath: [[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"] toPath: @"/tmp/OsiriXTables.pdf" error: nil];
		[[NSWorkspace sharedWorkspace] openFile: @"/tmp/OsiriXTables.pdf"];
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
		[routesArray replaceObjectAtIndex: [routesTable selectedRow] withObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [newName stringValue], @"name", [NSNumber numberWithBool:YES], @"activated", [newDescription stringValue], @"description", [newFilter stringValue], @"filter", [[serversArray objectAtIndex: [serverPopup indexOfSelectedItem]] objectForKey:@"Description"], @"server", [NSNumber numberWithInt: [previousPopup selectedTag]], @"previousStudies", [NSNumber numberWithBool: [previousModality state]], @"previousModality", [NSNumber numberWithBool: [previousDescription state]], @"previousDescription", [NSNumber numberWithInt: [failurePopup selectedTag]], @"failureRetry",  [NSNumber numberWithBool: [cfindTest state]], @"cfindTest", [NSNumber numberWithBool: filterType], @"filterType", nil]];
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

- (IBAction) selectPrevious:(id) sender
{
	if( [sender selectedTag])
	{
		[previousModality setEnabled: YES];
		[previousDescription setEnabled: YES];
	}
	else
	{
		[previousModality setEnabled: NO];
		[previousDescription setEnabled: NO];
	}
}

- (IBAction) selectServer:(id) sender
{
	int i = [sender indexOfSelectedItem];
	
	[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[serversArray objectAtIndex: i] objectForKey:@"Address"], [[serversArray objectAtIndex: i] objectForKey:@"Port"]]];
}

- (IBAction) editRoute:(id) sender
{
    newRouteMode = NO;
    
    if( [serversArray count] == 0)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"New Route", nil),NSLocalizedString( @"No destination servers exist. Create at least one destination in the Locations preferences.", nil),NSLocalizedString( @"OK", nil), nil, nil);
    }
    else
    {
        NSDictionary *selectedRoute = [routesArray objectAtIndex: [routesTable selectedRow]];
        
        if( selectedRoute)
        {
            int i;
            [serverPopup removeAllItems];
            for( i = 0; i < [serversArray count]; i++)
            {
                NSString *name = [NSString stringWithFormat:@"%@ - %@", [[serversArray objectAtIndex: i] objectForKey:@"AETitle"], [[serversArray objectAtIndex: i] objectForKey:@"Description"]];
                
                while( [serverPopup itemWithTitle: name] != nil)
                    name = [name stringByAppendingString: @" "];
                    
                [serverPopup addItemWithTitle: name];
            }
            
            [newName setStringValue: [selectedRoute valueForKey: @"name"]];
            [newDescription setStringValue: [selectedRoute valueForKey: @"description"]];
            [newFilter setStringValue: [selectedRoute valueForKey: @"filter"]];
            [previousPopup selectItemWithTag: [[selectedRoute valueForKey: @"previousStudies"] intValue]];
            [previousModality setState: [[selectedRoute valueForKey: @"previousModality"] boolValue]];
            [previousDescription setState: [[selectedRoute valueForKey: @"previousDescription"] boolValue]];
            [cfindTest setState: [[selectedRoute valueForKey: @"cfindTest"] boolValue]];
            [failurePopup selectItemWithTag: [[selectedRoute valueForKey: @"failureRetry"] intValue]];
            
            self.filterType = [[selectedRoute valueForKey: @"filterType"] intValue];
            
            int count = 0;
            for( i = 0; i < [serversArray count]; i++)
            {
                if ([[[serversArray objectAtIndex: i] objectForKey:@"Description"] isEqualToString: [selectedRoute valueForKey: @"server"]])
                {
                    [serverPopup selectItemAtIndex: i];
                    count++;
                }
            }
            
            if( count > 1)
            {
                NSRunCriticalAlertPanel(NSLocalizedString(@"Multiples Servers", nil), [NSString stringWithFormat:NSLocalizedString( @"Warning, multiples destination servers have the same name: %@. Each destination should have a unique name.", nil), [selectedRoute valueForKey: @"server"]],NSLocalizedString( @"OK", nil), nil, nil);
            }
            
            [self selectServer: serverPopup];
            
            [NSApp beginSheet: newRoute modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        }
    }
}

- (IBAction) newRoute:(id) sender
{
    [routesArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: @"new route", @"name", @"", @"description", @"(series.study.modality contains[c] \"CT\")", @"filter", [[serversArray objectAtIndex: 0] objectForKey:@"Description"], @"server", @"20", @"failureRetry", @"0", @"filterType", nil]];
    
    [routesTable reloadData];
    
    [routesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: (long)[routesArray count]-1] byExtendingSelection: NO];
    
    [self editRoute: self];
    
    newRouteMode = YES;
}

- (void) deleteSelectedRow:(id)sender
{
    if( [sender tag] == 0)
    {
        [routesArray removeObjectAtIndex:[routesTable selectedRow]];
        [routesTable reloadData];
    }
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
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
    row:(NSInteger)rowIndex
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

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if( [[aTableColumn identifier] isEqualToString:@"activated"])
        [[routesArray objectAtIndex:rowIndex] setValue:anObject forKey: [aTableColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return YES;
}
@end
