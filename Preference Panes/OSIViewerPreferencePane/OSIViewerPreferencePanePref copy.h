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

#import <PreferencePanes/PreferencePanes.h>


@interface OSIViewerPreferencePanePref : NSPreferencePane 
{
	id preferenceController;
	IBOutlet NSButton *checkSaveLoadROI;
	IBOutlet NSMatrix *dicomInDatabase;
	IBOutlet NSMatrix *sizeMatrix;
	IBOutlet NSMatrix *textureMatrix;
	
}

- (void) mainViewDidLoad;
- (IBAction)setTextureSize:(id)sender;
- (IBAction)setExportSize:(id)sender;
- (IBAction)set3DSave:(id)sender;
- (IBAction)setSaveLoadROI:(id)sender;


@end
