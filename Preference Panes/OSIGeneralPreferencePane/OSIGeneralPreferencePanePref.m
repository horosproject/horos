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
	
    if ([aView isKindOfClass: [NSControl class]])
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
	NSLog(@"dealloc OSIGeneralPreferencePanePref");
	
	[super dealloc];
}

- (IBAction) setAuthentication: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"AUTHENTICATION"];
	
	// Reload our view !
	[[[[self mainView] window] windowController] selectFirstPane];
	
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.general"];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	
	[_authView updateStatus: self];
	
	//setup GUI
	[CheckUpdatesOnOff setState:[defaults boolForKey:@"CHECKUPDATES"]];
	[DcmTkJpegOnOff setState:[defaults boolForKey:@"DCMTKJPEG"]];
	[securityOnOff setState:[defaults boolForKey:@"AUTHENTICATION"]];
	
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
