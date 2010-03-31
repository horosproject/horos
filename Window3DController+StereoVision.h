//
// Program:   OsiriX
// 
// Created by Silvan Widmer on 8/25/09.
// 
// Copyright (c) LIB-EPFL
// All rights reserved.
// Distributed under GNU - GPL
// 
// See http://www.osirix-viewer.com/copyright.html for details.
// 
// This software is distributed WITHOUT ANY WARRANTY; without even
// the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.
// =========================================================================

#ifdef _STEREO_VISION_

#import <Cocoa/Cocoa.h>
#import "Window3DController.h"

#import <Foundation/Foundation.h>
#import "ColorTransferView.h"
#import "OpacityTransferView.h"
#import "NSFullScreenWindow.h"
#import "OSIWindowController.h"


#define DATABASEPATH				@"/DATABASE.noindex/"
#define STATEDATABASE				@"/3DSTATE/"


@class ROIVolume;
@class ViewerController;
@class DCMPix;
@class VTKView;


@interface Window3DController (StereoVision)


- (void) disableFullScreen;
- (void) enableFullScreen;

@end
#endif
