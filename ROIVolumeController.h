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




#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "ViewerController.h"
#import "Window3DController.h"

@class ROIVolumeView;

@interface ROIVolumeController : Window3DController
{
    IBOutlet ROIVolumeView			*view;
	IBOutlet NSTextField			*volumeField;
	
	IBOutlet NSButton				*showSurfaces, *showPoints, *showWireframe, *textured, *color;
	IBOutlet NSColorWell			*colorWell;
	IBOutlet NSSlider				*opacity;
	
	ViewerController				*viewer;
	ROI								*roi;
}

- (id) initWithPoints:(NSMutableArray*) pts :(float) volume :(ViewerController*) iviewer roi:(ROI*) iroi;
- (IBAction) changeParameters:(id) sender;
- (void) setDataString:(NSString*) s;
- (ViewerController*) viewer;
- (ROI*) roi;
@end