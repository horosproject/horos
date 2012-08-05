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

#import "VRFlyThruAdapter.h"
#import "VRController.h"
#import "VRView.h"

@implementation VRFlyThruAdapter

- (id) initWithVRController: (VRController*) aVRController
{
	self = [super initWithWindow3DController: aVRController];
		
	return self;
}

- (Camera*) getCurrentCamera
{
	Camera *cam = [[controller view] camera];
	[cam setPreviewImage: [[controller view] nsimage:TRUE]];
	return cam;
}

- (void) setCurrentViewToCamera:(Camera*) cam
{
	[[(VRController*)controller view] setCamera: cam];
	[[(VRController*)controller view] setNeedsDisplay:YES];
}

- (void) setCurrentViewToLowResolutionCamera:(Camera*) cam
{
	[[(VRController*)controller view] setLowResolutionCamera: cam];
}

- (NSImage*) getCurrentCameraImage: (BOOL) highQuality
{
	return [[controller view] nsimageQuicktime: highQuality];
}

- (void) prepareMovieGenerating
{
	[[(VRController*)controller view] setViewSizeToMatrix3DExport];
}

- (void) endMovieGenerating
{
	[[(VRController*)controller view] restoreViewSizeAfterMatrix3DExport];
}

@end
