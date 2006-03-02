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

- (void) mainViewDidLoad
{
	NSConnection *theConnection;
	theConnection = [NSConnection connectionWithRegisteredName:@"OsirixPreferences"  host:nil];
	preferenceController = [[theConnection rootProxy] retain];
	
	//setup GUI	
	[checkSaveLoadROI setState:[preferenceController saveLoadROI]];
	[dicomInDatabase selectCellWithTag:[preferenceController save3DinDatabase]];
	[sizeMatrix selectCellWithTag:[preferenceController exportOriginalSize]];
	[textureMatrix selectCellWithTag:[preferenceController textureLimit]];

}

- (IBAction)setTextureSize:(id)sender{
	[preferenceController setTextureSize:[(NSMatrix *)[sender selectedCell] tag]];
}
- (IBAction)setExportSize:(id)sender{
	[preferenceController setExportSize:[(NSMatrix *)[sender selectedCell] tag]];
}
- (IBAction)set3DSave:(id)sender{
	[preferenceController set3DSave:[(NSMatrix *)[sender selectedCell] tag]];
}
- (IBAction)setSaveLoadROI:(id)sender{
	[preferenceController setSaveLoadROI:[sender state]];
}

@end
