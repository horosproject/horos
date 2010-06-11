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

#import "Window3DController+StereoVision.h"
#import "BrowserController.h"
#import "Window3DController.h"
#import "Mailer.h"
#import "Papyrus3/Papyrus3.h"
// { Removed by P. Thevenaz on June 11, 2010
// #import "Accelerate.h"
// }
#import "DCMPix.h"
#import "VRController.h"
#import "printView.h"
#import "VRView.h"
#import "Notifications.h"


@implementation Window3DController (StereoVision)

// added SilvanWidmer
- (void) disableFullScreen
{
	FullScreenOn = -1;
}
// added SilvanWidmer
- (void) enableFullScreen
{
	FullScreenOn = 0;
}

@end
#endif

