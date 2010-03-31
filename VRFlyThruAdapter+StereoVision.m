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

#import "VRFlyThruAdapter+StereoVision.h"

#import "VRController.h"
#import "VRView.h"
#import "VRView+StereoVision.h"



@implementation VRFlyThruAdapter (StereoVision)

- (void) endMovieGenerating
{	//Added SilvanWidmer 20-08-09
	
	if([[(VRController*)controller view] StereoVisionOn])
		[[(VRController*)controller view] disableStereoModeLeftRight];
	else [[(VRController*)controller view] restoreViewSizeAfterMatrix3DExport];
}

@end
#endif
