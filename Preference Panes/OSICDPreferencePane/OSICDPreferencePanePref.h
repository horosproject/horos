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


@interface OSICDPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSButton			*mountOnOffButton,
								*unmountOnOffButton;
								
	IBOutlet NSMatrix			*dicomdirModeMatrix,
								*stillMovieModeMatrix;
								
	IBOutlet id					burnOsirixCheck,
								burnSupplementaryFolderCheck,
								supplementaryFolderPath;
}

- (void) mainViewDidLoad;
- (IBAction)setMountOnOff:(id)sender;
- (IBAction)setUnmountOnOff:(id)sender;
- (IBAction)setDicomdirMode:(id)sender;
- (IBAction)setStillMovieMode:(id)sender;
- (IBAction)setBurnOsirixApplication:(id)sender;
- (IBAction)chooseSupplementaryBurnPath:(id)sender;

@end
