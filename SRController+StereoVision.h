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
#ifdef _STEREO_VISION_
#import <Cocoa/Cocoa.h>
#import "SRController.h"
#import "DCMPix.h"
#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"

// Fly Thru
#import "FlyThruController.h"
#import "FlyThru.h"
#import "SRFlyThruAdapter.h"

// ROIs Volumes
#define roi3Dvolume

@class SRView;
@class ROIVolume;


/** \brief Window Controller for Surface Rendering */
@interface SRController ( StereoVision )

- (IBAction) ApplyGeometrieSettings: (id) sender;

@end

#endif


	