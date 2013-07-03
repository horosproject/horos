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
#import <OsiriXAPI/NSPreferencePane+OsiriX.h>


@implementation OSIHangingPreferencePanePref

@synthesize modalityForHangingProtocols;

- (NSArray*) currentHangingProtocol
{
    return [hangingProtocols objectForKey: modalityForHangingProtocols];
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
	hangingProtocols = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HANGINGPROTOCOLS"] mutableCopy];
	
	self.modalityForHangingProtocols = @"CR";
}

- (void)dealloc {
	[hangingProtocols release];
	self.modalityForHangingProtocols = nil;
	
	NSLog(@"dealloc OSIHangingPreferencePanePref");

	[super dealloc];
}

- (void)setModalityForHangingProtocols:(NSString*) m
{
    [self willChangeValueForKey: @"currentHangingProtocol"];
	[modalityForHangingProtocols autorelease];
	modalityForHangingProtocols = [m retain];
    [self didChangeValueForKey: @"currentHangingProtocol"];
}

- (IBAction)newHangingProtocol:(id)sender
{
	NSMutableDictionary *protocol = [NSMutableDictionary dictionary];
    [protocol setObject: NSLocalizedString( @"Study Description", nil) forKey:@"Study Description"];
    [protocol setObject:[NSNumber numberWithInt:1] forKey:@"WindowsTiling"];
	[protocol setObject:[NSNumber numberWithInt:1] forKey:@"ImageTiling"];

	NSMutableArray *hangingProtocolArray = [[[hangingProtocols objectForKey:modalityForHangingProtocols] mutableCopy] autorelease];
    [hangingProtocolArray addObject:protocol];
    [hangingProtocols setObject: hangingProtocolArray forKey: modalityForHangingProtocols];
	
    [[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];
}

- (void) deleteSelectedRow:(id)sender
{
    NSMutableArray *hangingProtocolArray = [[[hangingProtocols objectForKey:modalityForHangingProtocols] mutableCopy] autorelease];
    [hangingProtocols setObject: hangingProtocolArray forKey: modalityForHangingProtocols];
    [[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}
@end
