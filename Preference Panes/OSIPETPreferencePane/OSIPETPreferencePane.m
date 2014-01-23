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

#import "OSIPETPreferencePane.h"

@implementation OSIPETPreferencePane

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIPETPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}


- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
	
	[[NSUserDefaults standardUserDefaults] setObject:[DefaultCLUTMenu title] forKey: @"PET Default CLUT"];
	[[NSUserDefaults standardUserDefaults] setObject:[CLUTBlendingMenu title] forKey: @"PET Blending CLUT"];
	[[NSUserDefaults standardUserDefaults] setObject:[OpacityTableMenu title] forKey: @"PET Default Opacity Table"];
	[[NSUserDefaults standardUserDefaults] setInteger:[minimumValueText intValue] forKey: @"PETMinimumValue"];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIPETPreferencePane");
	
	[super dealloc];
}

- (IBAction) setWindowingMode: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey: @"PETWindowingMode"];
}

- (IBAction) setMinimumValue: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[minimumValueText intValue] forKey: @"PETMinimumValue"];
}

- (void) buildCLUTMenu :(NSPopUpButton*) clutPopup
{
    short							i;
    NSArray							*keys;
    NSArray							*sortedKeys;

	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    [[clutPopup menu] removeAllItems];
		
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:0L keyEquivalent:@""];
    }
}

- (void) buildOpacityTableMenu :(NSPopUpButton*) oPopup
{
    short							i;
    NSArray							*keys;
    NSArray							*sortedKeys;

	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    [[oPopup menu] removeAllItems];
	
	[[oPopup menu] addItemWithTitle: NSLocalizedString( @"Linear Table", 0L) action:0L keyEquivalent:@""];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[oPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:0L keyEquivalent:@""];
    }
}

- (void) mainViewDidLoad
{
	[minimumValueText setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"PETMinimumValue"]];
	[WindowingModeMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey:@"PETWindowingMode"]];
	
	if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString:@"B/W Inverse"])
		[CLUTMode selectCellWithTag: 0];
	else
		[CLUTMode selectCellWithTag: 1];
	
	[self buildCLUTMenu: DefaultCLUTMenu];
	[DefaultCLUTMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
	
	[self buildCLUTMenu: CLUTBlendingMenu];
	[CLUTBlendingMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Blending CLUT"]];
	
	[self buildOpacityTableMenu: OpacityTableMenu];
	[OpacityTableMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default Opacity Table"]];
}

- (IBAction) setPETCLUTfor3DMIP: (id) sender
{
	if( [[sender selectedCell] tag] == 0)
		[[NSUserDefaults standardUserDefaults] setObject:@"B/W Inverse" forKey: @"PET Clut Mode"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"Classic Mode" forKey: @"PET Clut Mode"];
}

@end
