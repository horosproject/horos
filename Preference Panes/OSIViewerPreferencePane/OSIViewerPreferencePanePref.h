/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <PreferencePanes/PreferencePanes.h>

@class AppController;

@interface OSIViewerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSButton						*autoHideMatrix,
											*openViewerCheck,
											*reverseScrollWheelCheck,
											*tilingCheck,
											*totoku12Bit;
	
	IBOutlet NSMatrix						*sizeMatrix,
											*windowSizeMatrix,
											*toolbarPanelMatrix;
											
	IBOutlet NSTextField					*iPhotoAlbumName;
	
	IBOutlet NSWindow						*mainWindow;
    
    IBOutlet NSButton* screensButton;
}

-(AppController*)appController;
- (void) mainViewDidLoad;
- (IBAction) setToolbarMatrix: (id) sender;
- (IBAction) setExportSize: (id) sender;
- (IBAction) setReverseScrollWheel: (id) sender;
- (IBAction) setOpenViewerBut: (id) sender;
- (IBAction) setAlbumName: (id) sender;
- (IBAction) setAutoHideMatrixState: (id) sender;
- (IBAction) setWindowSizeViewer: (id) sender;
- (IBAction) setAutoTiling: (id) sender;

@end
