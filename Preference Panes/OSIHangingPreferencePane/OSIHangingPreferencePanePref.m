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


#import "OSIHangingPreferencePanePref.h"
#import "NSArray+N2.h"
#import <OsiriXAPI/NSPreferencePane+OsiriX.h>


@implementation OSIHangingPreferencePanePref

@synthesize modalityForHangingProtocols;

+ (void) convertWLWWToMenuTag: (NSMutableDictionary*) protocol
{
    if( [[protocol objectForKey: @"WL"] floatValue] == 0 && [[protocol objectForKey: @"WW"] floatValue] == 0)
    {
        [protocol setObject: @100 forKey: @"WLWW"]; //Default
        return;
    }
         
    if( [[protocol objectForKey: @"WL"] floatValue] == 1 && [[protocol objectForKey: @"WW"] floatValue] == 1)
    {
        [protocol setObject: @101 forKey: @"WLWW"]; //Full Dynamic
        return;
    }
    
    NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
    NSArray *sortedKeys = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for( NSString *key in sortedKeys)
    {
        NSArray *a = [wlwwDict objectForKey: key];
        
        if( [[protocol objectForKey: @"WL"] floatValue] == [[a objectAtIndex:0] floatValue] && [[protocol objectForKey: @"WW"] floatValue] == [[a objectAtIndex:1] floatValue])
        {
            [protocol setObject: @([sortedKeys indexOfObject: key] + 1) forKey: @"WLWW"];
            return;
        }
    }
    
    [protocol setObject: @0 forKey: @"WLWW"];
    return;
}

+ (void) convertMenuTagToWLWW: (NSMutableDictionary*) protocol
{
    if( [protocol objectForKey: @"WLWW"] == nil)
        return;
    
    if( [[protocol objectForKey: @"WLWW"] intValue] == 100)
    {
        [protocol setObject: @0 forKey: @"WL"]; //Default
        [protocol setObject: @0 forKey: @"WW"];
        [protocol removeObjectForKey: @"WLWW"];
        return;
    }
    
    if( [[protocol objectForKey: @"WLWW"] intValue] == 101)
    {
        [protocol setObject: @1 forKey: @"WL"]; //Full
        [protocol setObject: @1 forKey: @"WW"];
        [protocol removeObjectForKey: @"WLWW"];
        return;
    }
    
    NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
    NSArray *sortedKeys = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    if( [[protocol objectForKey: @"WLWW"] intValue] > 0 && [[protocol objectForKey: @"WLWW"] intValue] <= sortedKeys.count)
    {
        NSString *key = [sortedKeys objectAtIndex: [[protocol objectForKey: @"WLWW"] intValue]-1];
        NSArray *a = [wlwwDict objectForKey: key];
        
        [protocol setObject: [a objectAtIndex:0] forKey: @"WL"];
        [protocol setObject: [a objectAtIndex:1] forKey: @"WW"];
        [protocol removeObjectForKey: @"WLWW"];
        return;
    }
    
    [protocol removeObjectForKey: @"WLWW"];
    
    return;
}

- (NSArray*) currentHangingProtocol
{
    NSArray *a = [hangingProtocols objectForKey: modalityForHangingProtocols];
    
    for( NSMutableDictionary *d in a)
    {
        if( [[d valueForKey: @"NumberOfComparativeToDisplay"] intValue] <= 0)
             [d setValue: [NSNumber numberWithInt: 1] forKey: @"NumberOfComparativeToDisplay"];
        
        [OSIHangingPreferencePanePref convertWLWWToMenuTag: d];
    }
    
    return a;
}

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIHangingPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        // Windows/Image/WLWW menus
        NSMenu *mainMenu = [NSApp mainMenu];
        NSMenu *viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
        NSMenu *tilingMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Image Tiling", nil)] submenu];
        NSMenu *wlwwMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
        
        [windowsTilingPopup removeAllItems];
        [imageTilingPopup removeAllItems];
        
        for( NSMenuItem *i in tilingMenu.itemArray)
        {
            [windowsTilingPopup addItem: [i.copy autorelease]];
            [imageTilingPopup addItem: [i.copy autorelease]];
        }
        
        for( NSMenuItem *i in windowsTilingPopup.itemArray)
            [i setAction: nil];
        
        for( NSMenuItem *i in imageTilingPopup.itemArray)
            [i setAction: nil];
        
        [WLWWPopup removeAllItems];
		NSArray *sortedKeys = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		[WLWWPopup addItemWithTitle:NSLocalizedString(@"Default WL & WW", nil) action: nil keyEquivalent:@""];
        [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: 100];
        
		[WLWWPopup addItemWithTitle:NSLocalizedString(@"Full dynamic", nil) action: nil keyEquivalent:@""];
		[[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: 101];
        
        [WLWWPopup addItemWithTitle:NSLocalizedString(@"Other", nil) action: nil keyEquivalent:@""];
        [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: 0];
        
		[WLWWPopup addItem: [NSMenuItem separatorItem]];
		
		for( int i = 0; i < [sortedKeys count]; i++)
		{
			[WLWWPopup addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action: nil keyEquivalent:@""];
            [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: i+1];
		}
	}
	
	return self;
}

- (void) mainViewDidLoad
{
	hangingProtocols = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HANGINGPROTOCOLS"] deepMutableCopy];
	
	self.modalityForHangingProtocols = @"CR";
}

- (void)dealloc
{
	[hangingProtocols release];
	self.modalityForHangingProtocols = nil;
	
	NSLog(@"dealloc OSIHangingPreferencePanePref");

	[super dealloc];
}

- (void)setModalityForHangingProtocols:(NSString*) m
{
    for( NSMutableDictionary *d in [hangingProtocols objectForKey: modalityForHangingProtocols])
        [OSIHangingPreferencePanePref convertMenuTagToWLWW: d];
    
    [self willChangeValueForKey: @"currentHangingProtocol"];
	[modalityForHangingProtocols autorelease];
	modalityForHangingProtocols = [m retain];
    [self didChangeValueForKey: @"currentHangingProtocol"];
}

- (IBAction)newHangingProtocol:(id)sender
{
	NSMutableDictionary *protocol = [NSMutableDictionary dictionary];
    [protocol setObject: [NSString stringWithFormat: @"%@ %d", NSLocalizedString( @"Character String", nil), (int) [[hangingProtocols objectForKey:modalityForHangingProtocols] count]] forKey:@"Study Description"];
    [protocol setObject: [NSNumber numberWithInt:1] forKey:@"WindowsTiling"];
	[protocol setObject: [NSNumber numberWithInt:1] forKey:@"ImageTiling"];
    [protocol setObject: [NSNumber numberWithInt:0] forKey:@"WL"]; // Default WL/WW
    [protocol setObject: [NSNumber numberWithInt:0] forKey:@"WW"];
    [protocol setObject: [NSNumber numberWithInt:100] forKey:@"WLWW"];
    [protocol setObject: [NSNumber numberWithInt:1] forKey:@"NumberOfComparativeToDisplay"];
    
    [self willChangeValueForKey: @"currentHangingProtocol"];
    [[hangingProtocols objectForKey:modalityForHangingProtocols] addObject:protocol];
    [self didChangeValueForKey: @"currentHangingProtocol"];
}

- (void) deleteSelectedRow:(NSTableView*)sender
{
    if( NSRunInformationalAlertPanel(NSLocalizedString( @"Delete Protocol", 0L), NSLocalizedString( @"Are you sure you want to delete the selected protocol?", 0L), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
    {
        [self willChangeValueForKey: @"currentHangingProtocol"];
        [[hangingProtocols objectForKey:modalityForHangingProtocols] removeObjectAtIndex: sender.selectedRow];
        [self didChangeValueForKey: @"currentHangingProtocol"];
    }
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
    for( NSArray *modality in hangingProtocols)
    {
        for( NSMutableDictionary *protocol in modality)
        {
            [OSIHangingPreferencePanePref convertMenuTagToWLWW: protocol];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];
}
@end

#pragma mark

@interface HangingTableView : NSTableView {
}

@end

@implementation HangingTableView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	if ((c == NSDeleteCharacter || c == NSBackspaceCharacter))
    {
        if( [self selectedRow] > 0)
            [(OSIHangingPreferencePanePref*)[self delegate] deleteSelectedRow: self];
        else
            NSRunCriticalAlertPanel( NSLocalizedString( @"Delete Protocol", 0L), NSLocalizedString( @"You cannot delete the default protocol", nil), NSLocalizedString( @"OK", nil), nil, nil);
	}
	else
        [super keyDown:event];
}

@end

