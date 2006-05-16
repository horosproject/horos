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
    [self enableControls: NO];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIGeneralPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[_authView setDelegate:self];
	[_authView setString:"com.osirix.general"];
	[_authView updateStatus:self];
	
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
	else [self enableControls: NO];

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
