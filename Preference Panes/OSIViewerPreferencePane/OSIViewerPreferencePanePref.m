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

#import "OSIViewerPreferencePanePref.h"

@implementation OSIViewerPreferencePanePref

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
	[[NSUserDefaults standardUserDefaults] setObject:[iPhotoAlbumName stringValue] forKey: @"ALBUMNAME"];
	
	NSLog(@"dealloc OSIViewerPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.viewer"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];

	
	[checkSaveLoadROI setState :[defaults boolForKey: @"SAVEROIS"]];
	[sizeMatrix selectCellWithTag: [defaults boolForKey: @"ORIGINALSIZE"]];
	
	[openViewerCheck setState: [defaults boolForKey: @"OPENVIEWER"]];
	[reverseScrollWheelCheck setState: [defaults boolForKey: @"Scroll Wheel Reversed"]];
	[multipleScreensMatrix selectCellWithTag: [defaults integerForKey: @"ReserveScreenForDB"]];
	[iPhotoAlbumName setStringValue: [defaults stringForKey: @"ALBUMNAME"]];
	[toolbarPanelMatrix selectCellWithTag:[defaults boolForKey: @"USEALWAYSTOOLBARPANEL"]];
	[autoHideMatrix setState: [defaults boolForKey: @"AUTOHIDEMATRIX"]];
	[noInterpolationCheck setState: [defaults boolForKey: @"NOINTERPOLATION"]];
	
	[windowSizeMatrix selectCellWithTag: [defaults integerForKey: @"WINDOWSIZEVIEWER"]];
	
	int i = [defaults integerForKey: @"MAX3DTEXTURE"], x = 1;
	
	while( i > 32)
	{
		i /= 2;
		x++;
	}
}


- (IBAction) setNoInterpolation: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"NOINTERPOLATION"];
}

- (IBAction) setWindowSizeViewer: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey: @"WINDOWSIZEVIEWER"];
}

- (IBAction) setMultipleScreens: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey: @"ReserveScreenForDB"];
}

- (IBAction) setToolbarMatrix: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey: @"USEALWAYSTOOLBARPANEL"];
}

- (IBAction) setAutoHideMatrixState: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"AUTOHIDEMATRIX"];
}

- (IBAction) setExportSize: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey: @"ORIGINALSIZE"];
}

- (IBAction) setSaveLoadROI: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"SAVEROIS"];
}

- (IBAction) setReverseScrollWheel: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"Scroll Wheel Reversed"];
}

- (IBAction) setOpenViewerBut: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"OPENVIEWER"];
}

- (IBAction) setAlbumName: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[iPhotoAlbumName stringValue] forKey: @"ALBUMNAME"];
}

@end
