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



#import <Cocoa/Cocoa.h>
#import "FlyThruAdapter.h"

@class VRPROController;

@interface VRPROFlyThruAdapter : FlyThruAdapter {
}

- (id) initWithVRController: (VRPROController*) aVRController;
- (NSImage*) getCurrentCameraImage: (BOOL) highQuality;

@end
