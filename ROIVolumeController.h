/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "ViewerController.h"
#import "Window3DController.h"

@class ROIVolumeView;

/** \brief  Window Controller for ROI Volume display */

@interface ROIVolumeController : Window3DController <NSWindowDelegate>
{
    IBOutlet ROIVolumeView			*view;
	IBOutlet NSTextField			*volumeField, *seriesName;
	
	IBOutlet NSButton				*showSurfaces, *showPoints, *showWireframe, *textured, *color;
	IBOutlet NSColorWell			*colorWell;
	IBOutlet NSSlider				*opacity;
	
	ViewerController				*viewer;
	ROI								*roi;
}

@property (readonly) NSTextField *volumeField, *seriesName;

- (id) initWithPoints:(NSMutableArray*) pts :(float) volume :(ViewerController*) iviewer roi:(ROI*) iroi;
- (IBAction) changeParameters:(id) sender;
- (void) setDataString:(NSString*) s volume:(NSString*) v;
- (ViewerController*) viewer;
- (ROI*) roi;
- (IBAction) reload:(id)sender;
@end