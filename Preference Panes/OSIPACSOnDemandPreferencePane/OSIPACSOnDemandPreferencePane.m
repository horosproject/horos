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
#import "DicomDatabase.h"
#import "DicomAlbum.h"
#import "N2Debug.h"

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
    //Take an NSArray to NSString
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
        
        gDateMatrix = dateMatrix;
        
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
    [smartAlbumsArray release];
    
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Smart Albums
    
    self.smartAlbumsArray = [[[[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"] mutableCopy] autorelease];
    if( self.smartAlbumsArray == nil)
        self.smartAlbumsArray = [NSMutableArray array];
    
    [self willChangeValueForKey: @"smartAlbumsArray"];
    [[DicomDatabase activeLocalDatabase] lock];
    @try
    {
        NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
        [dbRequest setEntity: [[DicomDatabase activeLocalDatabase] entityForName: @"Album"]];
        [dbRequest setPredicate: [NSPredicate predicateWithFormat: @"smartAlbum == YES"]];
        NSError *error = nil;
        NSArray *albumArray = [[[DicomDatabase activeLocalDatabase] managedObjectContext] executeFetchRequest:dbRequest error:&error];
        
        albumArray = [albumArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES]]];
        
        for( DicomAlbum *album in albumArray)
        {
            if( [self.smartAlbumsArray containsObject: album.name] == NO)
            {
                [self.smartAlbumsArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", album.predicateString, @"predicateString", album.name, @"name", @"0", @"date", [NSArray arrayWithObjects: @"CT", @"MR", nil], @"modality", nil]];
            }
        }
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    [[DicomDatabase activeLocalDatabase] unlock];
    [self didChangeValueForKey: @"smartAlbumsArray"];
    
    [smartAlbumsTable setDoubleAction: @selector( editSmartAlbumFilter:)];
    [smartAlbumsTable setTarget: self];
    
    // History
    
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

- (IBAction) endEditSmartAlbumFilter:(id) sender
{
	if( [sender tag] == 1) // OK
	{
        [self willChangeValueForKey: @"smartAlbumsArray"];
        
        NSMutableDictionary *dict = [smartAlbumsArray objectAtIndex: [smartAlbumsTable selectedRow]];
        
        [dict setObject: [NSNumber numberWithInt: self.smartAlbumDate] forKey: @"date"];
        [dict setObject: self.smartAlbumModality forKey: @"modality"];
        
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
//	if([self isUnlocked])
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
                self.smartAlbumFilter = [selectedAlbum objectForKey: @"predicateString"];
                
				[NSApp beginSheet: smartAlbumsEditWindow modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
			}
		}
	}
}

@end
