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
- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] setObject:[iPhotoAlbumName stringValue] forKey: @"ALBUMNAME"];
	
	NSLog(@"dealloc OSIViewerPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
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
