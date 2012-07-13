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

#import "OSIPACSOnDemandPreferencePane.h"
#import "DCMNetServiceDelegate.h"

@implementation OSIPACSOnDemandPreferencePane

- (IBAction) selectUniqueSource:(id) sender
{
	[self willChangeValueForKey:@"sourcesArray"];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		NSMutableDictionary		*source = [NSMutableDictionary dictionaryWithDictionary: [sourcesArray objectAtIndex: i]];
		
		if( [sender selectedRow] == i) [source setObject: [NSNumber numberWithBool:YES] forKey:@"activated"];
		else [source setObject: [NSNumber numberWithBool:NO] forKey:@"activated"];
		
		[sourcesArray	replaceObjectAtIndex: i withObject:source];
	}
	
	[self didChangeValueForKey:@"sourcesArray"];
}

- (NSDictionary*) findCorrespondingServer: (NSDictionary*) savedServer inServers : (NSArray*) servers
{
	for( NSUInteger i = 0 ; i < [servers count]; i++)
	{
        @try
        {
            if( [[savedServer objectForKey:@"AETitle"] isEqualToString: [[servers objectAtIndex:i] objectForKey:@"AETitle"]] && 
               [[savedServer objectForKey:@"AddressAndPort"] isEqualToString: [NSString stringWithFormat:@"%@:%@", [[servers objectAtIndex:i] valueForKey:@"Address"], [[servers objectAtIndex:i] valueForKey:@"Port"]]])
            {
                return [servers objectAtIndex:i];
            }
        }
        @catch (NSException *exception)
        {
        }
	}
	
	return nil;
}

- (void) refreshSources
{
	[[NSUserDefaults standardUserDefaults] setObject: sourcesArray forKey: @"comparativeSearchDICOMNodes"];
	
	NSMutableArray *serversArray = [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
	NSArray	*savedArray	= [[NSUserDefaults standardUserDefaults] arrayForKey: @"comparativeSearchDICOMNodes"];
	
	[self willChangeValueForKey:@"sourcesArray"];
    
	[sourcesArray removeAllObjects];
	
	for( NSUInteger i = 0; i < [savedArray count]; i++)
	{
		NSDictionary *server = [self findCorrespondingServer: [savedArray objectAtIndex:i] inServers: serversArray];
		
		if( server && ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
		{
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[[savedArray objectAtIndex: i] valueForKey:@"activated"], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
			
			[serversArray removeObject: server];
		}
	}
	
	for( NSUInteger i = 0; i < [serversArray count]; i++)
	{
		NSDictionary *server = [serversArray objectAtIndex: i];
		
		if( ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
            
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
	}
	
	[sourcesTable reloadData];
	
	[self didChangeValueForKey:@"sourcesArray"];
}

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSIPACSOnDemand" bundle: nil];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}


- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
    NSMutableArray *srcArray = [NSMutableArray array];
    for( id src in sourcesArray)
    {
        if( [[src valueForKey: @"activated"] boolValue] == YES)
            [srcArray addObject: src];
    }
    
    if( [srcArray count] == 0 && [sourcesTable selectedRow] >= 0)
        [srcArray addObject: [sourcesArray objectAtIndex: [sourcesTable selectedRow]]];
    
    [[NSUserDefaults standardUserDefaults] setValue: srcArray forKey: @"comparativeSearchDICOMNodes"];

}

- (void) dealloc
{
	NSLog(@"dealloc OSIPACSOnDemandPreferencePane");
	
    [sourcesArray release];
    
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    sourcesArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"comparativeSearchDICOMNodes"] mutableCopy];
    if( sourcesArray == nil) sourcesArray = [[NSMutableArray array] retain];
    
    [sourcesTable setDoubleAction: @selector( selectUniqueSource:)];
    
    [self refreshSources];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
		{
			[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
			[sourcesTable scrollRowToVisible: i];
			break;
		}
	}
}
@end
