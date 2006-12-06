/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import "VRPROFlyThruAdapter.h"
#import "VRControllerVPRO.h"


@implementation VRPROFlyThruAdapter

- (id) initWithVRController: (VRPROController*) aVRController
{
	[super initWithWindow3DController: aVRController];
	
	return self;
}

- (Camera*) getCurrentCamera
{
	Camera *cam = [[controller view] camera];
	[cam setPreviewImage: [[[controller view] nsimage:TRUE] autorelease]];
	return cam;
}

- (void) setCurrentViewToCamera:(Camera*) cam
{
	[[(VRPROController*)controller view] setCamera: cam];
	[[(VRPROController*)controller view] setNeedsDisplay:YES];
}

- (void) setCurrentViewToLowResolutionCamera:(Camera*) cam
{
	[[(VRPROController*)controller view] setLowResolutionCamera: cam];
}

- (NSImage*) getCurrentCameraImage: (BOOL) highQuality
{
	return [[[controller view] nsimageQuicktime] autorelease];
}

- (void) prepareMovieGenerating
{
	[[(VRPROController*)controller view] setViewSizeToMatrix3DExport];
}

- (void) endMovieGenerating
{
	[[(VRPROController*)controller view] restoreViewSizeAfterMatrix3DExport];
}
@end
