/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
