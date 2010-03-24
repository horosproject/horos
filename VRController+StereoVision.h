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
#import "VRController.h"
#import "DCMPix.h"
#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"
#import "ShadingArrayController.h"

// Fly Thru
#import "FlyThruController.h"
#import "FlyThru.h"
#import "VRFlyThruAdapter.h"

// ROIs Volumes
#define roi3Dvolume

@class CLUTOpacityView;
@class VRView;
@class ROIVolume;

@class VRPresetPreview;
#import "ColorView.h"


@interface VRController (StereoVision)

- (IBAction) ApplyGeometrieSettings: (id) sender;


@end
#endif
