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

@interface OSIViewerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSButton						*checkSaveLoadROI,
											*autoHideMatrix,
											*openViewerCheck,
											*reverseScrollWheelCheck,
											*tilingCheck;
	
	IBOutlet NSMatrix						*sizeMatrix,
											*multipleScreensMatrix,
											*windowSizeMatrix,
											*toolbarPanelMatrix;
											
	IBOutlet NSTextField					*iPhotoAlbumName;
	
	IBOutlet SFAuthorizationView			*_authView;
}

- (void) mainViewDidLoad;
- (IBAction) setToolbarMatrix: (id) sender;
- (IBAction) setExportSize: (id) sender;
- (IBAction) setSaveLoadROI: (id) sender;
- (IBAction) setReverseScrollWheel: (id) sender;
- (IBAction) setOpenViewerBut: (id) sender;
- (IBAction) setMultipleScreens: (id) sender;
- (IBAction) setAlbumName: (id) sender;
- (IBAction) setAutoHideMatrixState: (id) sender;
- (IBAction) setWindowSizeViewer: (id) sender;
- (IBAction) setAutoTiling: (id) sender;
@end
