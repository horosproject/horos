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

#import "OSIPETPreferencePane.h"

@implementation OSIPETPreferencePane

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

//	[characterSetPopup setEnabled: val];
//	[addServerDICOM setEnabled: val];
//	[addServerSharing setEnabled: val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIPETPreferencePane");
	
	[[NSUserDefaults standardUserDefaults] setObject:[DefaultCLUTMenu title] forKey: @"PET Default CLUT"];
	[[NSUserDefaults standardUserDefaults] setObject:[CLUTBlendingMenu title] forKey: @"PET Blending CLUT"];
	[[NSUserDefaults standardUserDefaults] setInteger:[minimumValueText intValue] forKey: @"PETMinimumValue"];
	
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
	//*** Build the CLUT menu
    short							i;
    NSArray							*keys;
    NSArray							*sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[clutPopup menu] numberOfItems];
    while(i-- > 0) [[clutPopup menu] removeItemAtIndex:0];
		
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:0L keyEquivalent:@""];
    }
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[_authView setDelegate:self];
	[_authView setString:"com.rossetantoine.osirix.preferences.pet"];
	[_authView updateStatus:self];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else [_authView setEnabled: NO];

	[minimumValueText setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"PETMinimumValue"]];
	[WindowingModeMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey:@"PETWindowingMode"]];
	
	[convertPETtoSUVCheck setState: [defaults boolForKey: @"ConvertPETtoSUVautomatically"]];
	
	if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString:@"B/W Inverse"])
		[CLUTMode selectCellWithTag: 0];
	else
		[CLUTMode selectCellWithTag: 1];
	
	[self buildCLUTMenu: DefaultCLUTMenu];
	[DefaultCLUTMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
	
	[self buildCLUTMenu: CLUTBlendingMenu];
	[CLUTBlendingMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Blending CLUT"]];
}

- (IBAction) setPETCLUTfor3DMIP: (id) sender
{
	if( [[sender selectedCell] tag] == 0)
		[[NSUserDefaults standardUserDefaults] setObject:@"B/W Inverse" forKey: @"PET Clut Mode"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"Classic Mode" forKey: @"PET Clut Mode"];
}

- (IBAction) setConvertPETtoSUVautomatically: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"ConvertPETtoSUVautomatically"];
}
@end
