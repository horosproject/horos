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
#import <SecurityInterface/SFAuthorizationView.h>

@interface OSICDPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSButton			*mountOnOffButton,
								*unmountOnOffButton;
								
	IBOutlet NSMatrix			*dicomdirModeMatrix,
								*stillMovieModeMatrix;
								
	IBOutlet NSButton			*burnOsirixCheck;
	IBOutlet NSButton			*burnHtmlCheck;
	IBOutlet NSButton			*supplementaryFolderCheck;
								
	IBOutlet NSTextField		*supplementaryFolderPath;
								
	IBOutlet SFAuthorizationView	*_authView;
}

- (void) mainViewDidLoad;
- (IBAction)setMountOnOff:(id)sender;
- (IBAction)setUnmountOnOff:(id)sender;
- (IBAction)setDicomdirMode:(id)sender;
- (IBAction)setStillMovieMode:(id)sender;
- (IBAction)setBurnOsirixApplication:(id)sender;
- (IBAction)setBurnHtml:(id)sender;
- (IBAction)chooseSupplementaryBurnPath:(id)sender;
- (IBAction)setBurnSupplementaryFolder:(id)sender;
@end
