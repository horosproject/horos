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

@interface OSI3DPreferencePanePref : NSPreferencePane 
{
//	IBOutlet NSSlider						*bestRenderingSlider, *max3DTextureSlider, *max3DTextureSliderShading;
//	IBOutlet NSTextField					*bestRenderingString, *max3DTextureString, *max3DTextureStringShading;
//	IBOutlet NSTextField					*recommandations;

	IBOutlet NSWindow *mainWindow;
}

- (void) mainViewDidLoad;

//- (IBAction) setBestRendering: (id) sender;
//- (IBAction) setMax3DTexture: (id) sender;
//- (IBAction) setMax3DTextureShading: (id) sender;
@end
