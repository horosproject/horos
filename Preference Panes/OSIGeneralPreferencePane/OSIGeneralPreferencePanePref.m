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


#import "OSIGeneralPreferencePanePref.h"

@implementation OSIGeneralPreferencePanePref
- (void) dealloc
{
	NSLog(@"dealloc OSIGeneralPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	//setup GUI
	[CheckUpdatesOnOff setState:[defaults boolForKey:@"CHECKUPDATES"]];
	[DcmTkJpegOnOff setState:[defaults boolForKey:@"DCMTKJPEG"]];
	
	[readerMatrix selectCellWithTag: [defaults boolForKey: @"USEPAPYRUSDCMPIX"]];
	[parserMatrix selectCellWithTag: [defaults boolForKey: @"USEPAPYRUSDCMFILE"]];
}

- (IBAction) setReader: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey: @"USEPAPYRUSDCMPIX"];
}

- (IBAction) setParser: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey: @"USEPAPYRUSDCMFILE"];
}

-(IBAction)setCheckUpdates:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"CHECKUPDATES"];
}

-(IBAction)setUseDCMTK:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"DCMTKJPEG"];
}
-(IBAction)setUseTransistion:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"TRANSITIONEFFECT"];
}
-(IBAction)setTransitionType:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedItem] tag] forKey:@"TRANSITIONTYPE"];
}
@end
