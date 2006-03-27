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
	IBOutlet NSButton						*checkSaveLoadROI,
											*autoHideMatrix,
											*openViewerCheck,
											*reverseScrollWheelCheck,
											*noInterpolationCheck,
											*convertPETtoSUVCheck,
											*preferWonBforPET3D;
	
	IBOutlet NSSlider						*bestRenderingSlider, *max3DTextureSlider, *max3DTextureSliderShading;
	
	IBOutlet NSMatrix						*sizeMatrix,
											*multipleScreensMatrix,
											*windowSizeMatrix,
											*toolbarPanelMatrix;
											
	IBOutlet NSTextField					*iPhotoAlbumName, *max3DTextureString, *max3DTextureStringShading, *bestRenderingString;
	
	IBOutlet NSTextField					*recommandations;
}

- (void) mainViewDidLoad;
- (IBAction) setPETCLUTfor3DMIP: (id) sender;
- (IBAction) setToolbarMatrix: (id) sender;
- (IBAction) setExportSize: (id) sender;
- (IBAction) setSaveLoadROI: (id) sender;
- (IBAction) setReverseScrollWheel: (id) sender;
- (IBAction) setOpenViewerBut: (id) sender;
- (IBAction) setMultipleScreens: (id) sender;
- (IBAction) setAlbumName: (id) sender;
- (IBAction) setAutoHideMatrixState: (id) sender;
- (IBAction) setBestRendering: (id) sender;
- (IBAction) setMax3DTexture: (id) sender;
- (IBAction) setMax3DTextureShading: (id) sender;
- (IBAction) setNoInterpolation: (id) sender;
- (IBAction) setWindowSizeViewer: (id) sender;
- (IBAction) setConvertPETtoSUVautomatically: (id) sender;
@end
