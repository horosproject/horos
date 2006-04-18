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


@interface OSI3DPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSSlider						*bestRenderingSlider, *max3DTextureSlider, *max3DTextureSliderShading;
	
	IBOutlet NSTextField					*max3DTextureString, *max3DTextureStringShading, *bestRenderingString;
	
	IBOutlet NSTextField					*recommandations;
}

- (void) mainViewDidLoad;
- (IBAction) setBestRendering: (id) sender;
- (IBAction) setMax3DTexture: (id) sender;
- (IBAction) setMax3DTextureShading: (id) sender;
@end
