/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

#import "OSIPACSOnDemandPreferencePane.h"
#import "DCMNetServiceDelegate.h"
#import "DicomDatabase.h"
#import "DicomAlbum.h"
#import "N2Debug.h"
#import "BrowserController.h"

static NSMatrix *gDateMatrix = nil;

@interface ArrayToListTransformer: NSValueTransformer {}
@end
@implementation ArrayToListTransformer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(NSArray*) array {
    NSMutableString *string = [NSMutableString string];
    for( NSString *modality in array)
    {
        [string appendString: modality];
        if( modality != array.lastObject)
            [string appendString:@", "];
    }
    return string;
}
@end

@interface DateEnumTransformer: NSValueTransformer {}
@end
@implementation DateEnumTransformer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSNumber class];
}

- (id)transformedValue:(NSNumber*) number {
    return [[gDateMatrix cellWithTag: number.intValue] title];
}
@end


@implementation OSIPACSOnDemandPreferencePane

@synthesize smartAlbumsArray, smartAlbumModality, smartAlbumDate, smartAlbumFilter;

- (void) selectUniqueSource:(id) sender
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
               [[savedServer objectForKey:@"name"] isEqualToString: [[servers objectAtIndex:i] objectForKey:@"Description"]] &&
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
		
		//if( server && ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
		{
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[[savedArray objectAtIndex: i] valueForKey:@"activated"], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
			
			[serversArray removeObject: server];
		}
	}
	
	for( NSUInteger i = 0; i < [serversArray count]; i++)
	{
		NSDictionary *server = [serversArray objectAtIndex: i];
		
		//if( ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
            
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
	}
	
	[sourcesTable reloadData];
	
	[self didChangeValueForKey:@"sourcesArray"];
}

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIPACSOnDemand" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
        [_tlos retain];
        
        [smartAlbumsEditWindow retain];
        
		[self setMainView: [mainWindow contentView]];
        
        gDateMatrix = [dateMatrix retain];
        
		[self mainViewDidLoad];
	}
	
	return self;
}

- (IBAction) setActivated:(id) sender
{
    // Check that activated smart albums have at least date or modality filters
    for( NSMutableDictionary *d in smartAlbumsArray)
    {
        if( [[d objectForKey: @"activated"] boolValue])
        {
            if( [[d objectForKey: @"date"] intValue] == 0 && [[d objectForKey: @"modality"] count] == 0)
            {
                NSRunInformationalAlertPanel( NSLocalizedString( @"Filter", nil), NSLocalizedString( @"The Smart Album filter (%@) needs to have at least one parameter defined to be activated: date or modality.", nil), NSLocalizedString( @"OK", nil), nil, nil, [d objectForKey: @"name"]);
                
                [self willChangeValueForKey: @"smartAlbumsArray"];
                [d setValue: [NSNumber numberWithBool: NO] forKey: @"activated"];
                [self didChangeValueForKey: @"smartAlbumsArray"];
            }
        }
    }
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
    // Save DICOM Nodes
    
    NSMutableArray *srcArray = [NSMutableArray array];
    for( id src in sourcesArray)
    {
        if( [[src valueForKey: @"activated"] boolValue] == YES)
            [srcArray addObject: src];
    }
    if( srcArray.count == 0)
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"searchForComparativeStudiesOnDICOMNodes"];
    
    [[NSUserDefaults standardUserDefaults] setValue: srcArray forKey: @"comparativeSearchDICOMNodes"];
    
    // Save Smart Albums
    [self setActivated: self];
    [[NSUserDefaults standardUserDefaults] setObject: smartAlbumsArray forKey: @"smartAlbumStudiesDICOMNodes"];
    
    // Refresh Smart Albums
    [[BrowserController currentBrowser] refreshAlbums];
    [[BrowserController currentBrowser] refreshComparativeStudiesIfNeeded: nil];
    [[BrowserController currentBrowser] outlineViewRefresh];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIPACSOnDemandPreferencePane");
    
    [sourcesArray release];
    [smartAlbumsArray release];
    [albumDBArray release];
    
    [gDateMatrix release]; gDateMatrix = nil;
    
    [smartAlbumsEditWindow release];
    
    [_tlos release]; _tlos = nil;
    
	[super dealloc];
}

- (void) willSelect
{
    // Smart Albums
    NSMutableArray *savedSmartAlbums = [NSMutableArray array];
    
    // Create mutable version...
    for( NSDictionary *d in [[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"])
        [savedSmartAlbums addObject: [NSMutableDictionary dictionaryWithDictionary: d]];
    
    [self willChangeValueForKey: @"smartAlbumsArray"];
    
    self.smartAlbumsArray = savedSmartAlbums;
    
    @try
    {
        NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
        [dbRequest setEntity: [[DicomDatabase activeLocalDatabase] entityForName: @"Album"]];
        [dbRequest setPredicate: [NSPredicate predicateWithFormat: @"smartAlbum == YES"]];
        NSError *error = nil;
        
        [albumDBArray release];
        
        albumDBArray = [[[DicomDatabase activeLocalDatabase] managedObjectContext] executeFetchRequest:dbRequest error:&error];
        albumDBArray = [albumDBArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES]]];
        
        [albumDBArray retain];
        
        // Add mising smart albums
        for( DicomAlbum *album in albumDBArray)
        {
            if( [[self.smartAlbumsArray valueForKey: @"name"] containsObject: album.name] == NO)
            {
                // Is it a 'known' album : pre-fill it
                
                if( [album.name isEqualToString: NSLocalizedString( @"Just Acquired (last hour)", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"101", @"date", [NSArray array], @"modality", nil]];
                
                else if( [album.name isEqualToString: NSLocalizedString( @"Today MR", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"MR"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Today CT", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"CT"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Today US", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"US"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Today MG", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"MG"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Today CR", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"CR"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Today XA", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"XA"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Today RF", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"1", @"date", [NSArray arrayWithObject:@"RF"], @"modality", nil]];
                
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday MR", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"MR"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday CT", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"CT"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday US", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"US"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday MG", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"MG"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday CR", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"CR"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday XA", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"XA"], @"modality", nil]];
                else if( [album.name isEqualToString: NSLocalizedString( @"Yesterday RF", nil)])
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES], @"activated", album.name, @"name", @"2", @"date", [NSArray arrayWithObject:@"RF"], @"modality", nil]];
                
                else
                    [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", album.name, @"name", @"0", @"date", [NSArray array], @"modality", nil]];
            }
        }
        
        // Delete unavailble smart albums preferences
        NSMutableArray *toBeRemoved = [NSMutableArray array];
        for( NSDictionary *album in smartAlbumsArray)
        {
            if( [[albumDBArray valueForKey: @"name"] containsObject: [album objectForKey: @"name"]] == NO)
                [toBeRemoved addObject: album];
        }
        
        [smartAlbumsArray removeObjectsInArray: toBeRemoved];
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    [self didChangeValueForKey: @"smartAlbumsArray"];
    
    // History
    [sourcesArray release];
    sourcesArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"comparativeSearchDICOMNodes"] mutableCopy];
    if( sourcesArray == nil)
        sourcesArray = [[NSMutableArray array] retain];
    
    [self refreshSources];
}

- (void) mainViewDidLoad
{
    [smartAlbumsTable setDoubleAction: @selector(editSmartAlbumFilter:)];
    [smartAlbumsTable setTarget: self];
    
    [sourcesTable setDoubleAction: @selector(selectUniqueSource:)];
    
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

- (IBAction) endEditSmartAlbumFilter:(id) sender
{
	if( [sender tag] == 1) // OK
	{
        [self willChangeValueForKey: @"smartAlbumsArray"];
        
        NSMutableDictionary *dict = [smartAlbumsArray objectAtIndex: [smartAlbumsTable selectedRow]];
        
        [dict setObject: [NSNumber numberWithInt: self.smartAlbumDate] forKey: @"date"];
        
        if( self.smartAlbumModality)
            [dict setObject: self.smartAlbumModality forKey: @"modality"];
        else
            [dict setObject: [NSArray array] forKey: @"modality"];
        
        [self didChangeValueForKey: @"smartAlbumsArray"];
	}
	else // Cancel
	{
	}
	
	[smartAlbumsEditWindow orderOut:sender];
	[NSApp endSheet: smartAlbumsEditWindow returnCode:[sender tag]];
}

- (IBAction) editSmartAlbumFilter:(id) sender
{
    if( [smartAlbumsArray count] == 0)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"New Route", nil),NSLocalizedString( @"No smart album exists.", nil),NSLocalizedString( @"OK", nil), nil, nil);
    }
    else
    {
        NSDictionary *selectedAlbum = [smartAlbumsArray objectAtIndex: [smartAlbumsTable selectedRow]];
        
        if( selectedAlbum)
        {
            self.smartAlbumModality = [selectedAlbum objectForKey: @"modality"];
            self.smartAlbumDate = [[selectedAlbum objectForKey: @"date"] intValue];
            
            NSUInteger index = [[albumDBArray valueForKey: @"name"] indexOfObject: [selectedAlbum objectForKey: @"name"]];
            self.smartAlbumFilter = [[albumDBArray objectAtIndex: index] valueForKey: @"predicateString"];
            
            [NSApp beginSheet: smartAlbumsEditWindow modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        }
    }
}

@end
