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
- (void) dealloc
{
	NSLog(@"dealloc OSIPETPreferencePane");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
	[convertPETtoSUVCheck setState: [defaults boolForKey: @"ConvertPETtoSUVautomatically"]];
	
	if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut MIP"] isEqualToString:@"B/W Inverse"])
		[preferWonBforPET3D setState: NSOnState];
	else
		[preferWonBforPET3D setState: NSOffState];
}

- (IBAction) setPETCLUTfor3DMIP: (id) sender
{
	if( [sender state])
		[[NSUserDefaults standardUserDefaults] setObject:@"B/W Inverse" forKey: @"PET Clut MIP"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"PET" forKey: @"PET Clut MIP"];
}

- (IBAction) setConvertPETtoSUVautomatically: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"ConvertPETtoSUVautomatically"];
}
@end
