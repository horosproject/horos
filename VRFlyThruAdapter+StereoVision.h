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
#import "VRFlyThruAdapter.h"

#import "FlyThruAdapter.h"

@interface VRFlyThruAdapter ( StereoVision )

- (void) endMovieGenerating;

@end
#endif
