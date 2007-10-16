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



#import <Cocoa/Cocoa.h>
#import "FlyThruAdapter.h"

@class VRPROController;

/** \brief FlyThruAdapter for VRPro
*
*
* FlyThruAdapter for VRPro
*/

@interface VRPROFlyThruAdapter : FlyThruAdapter {
}

- (id) initWithVRController: (VRPROController*) aVRController;
- (NSImage*) getCurrentCameraImage: (BOOL) highQuality;

@end
