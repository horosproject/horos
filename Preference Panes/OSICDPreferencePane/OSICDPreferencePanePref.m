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

#import "OSICDPreferencePanePref.h"

@implementation OSICDPreferencePanePref
- (void) dealloc
{
	NSLog(@"dealloc OSICDPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	//setup GUI
	[mountOnOffButton setState:[defaults boolForKey:@"MOUNT"]];
	[unmountOnOffButton setState: [defaults boolForKey:@"UNMOUNT"]];
	[dicomdirModeMatrix selectCellWithTag: [defaults boolForKey:@"USEDICOMDIR"]];
	[stillMovieModeMatrix selectCellWithTag: [defaults integerForKey:@"STILLMOVIEMODE"]];

	[burnOsirixCheck setIntValue: [[[NSUserDefaults standardUserDefaults] objectForKey: @"Burn Osirix Application"] intValue]];
	[burnSupplementaryFolderCheck setIntValue: [[[NSUserDefaults standardUserDefaults] objectForKey: @"Burn Supplementary Folder"] intValue]];
	[supplementaryFolderPath setStringValue: [[NSUserDefaults standardUserDefaults] stringForKey: @"Supplementary Burn Path"]];
}



- (IBAction)setMountOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"MOUNT"];
}
- (IBAction)setUnmountOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"UNMOUNT"];
}
- (IBAction)setDicomdirMode:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey:@"USEDICOMDIR"];
}
- (IBAction)setStillMovieMode:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey:@"STILLMOVIEMODE"];
}
- (IBAction)setBurnOsirixApplication:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool: [sender state] forKey:@"Burn Osirix Application"];
}
- (IBAction)setBurnSupplementaryFolder:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool: [sender state] forKey:@"Burn Supplementary Folder"];
}
- (IBAction)chooseSupplementaryBurnPath: (id)sender{
	NSOpenPanel				*openPanel;
	NSString				*filename;
	BOOL					result;
	
	
	openPanel=[NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories: YES];
	[openPanel setCanChooseFiles: NO];
	result=[openPanel runModalForDirectory: Nil file: Nil types: Nil];
	if (result)
	{
		filename=[[[openPanel filenames] objectAtIndex: 0] stringByAbbreviatingWithTildeInPath];
		[[NSUserDefaults standardUserDefaults] setObject: filename forKey:@"Supplementary Burn Path"];
		[supplementaryFolderPath setStringValue: filename];
	}
}

@end
