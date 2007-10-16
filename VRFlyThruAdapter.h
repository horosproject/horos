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

/** \brief Flythru adaptor for VR
* Volume Rendering Flythru adaptor
*/


#import <Cocoa/Cocoa.h>
#import "FlyThruAdapter.h"

@class VRController;

@interface VRFlyThruAdapter : FlyThruAdapter {
}

- (id) initWithVRController: (VRController*) aVRController;
- (NSImage*) getCurrentCameraImage: (BOOL) highQuality;

@end
