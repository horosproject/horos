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

#import "OSIPETPreferencePane.h"

@implementation OSIPETPreferencePane

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIPETPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
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
    
    [_tlos release]; _tlos = nil;
	
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
