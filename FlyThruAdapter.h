/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Cocoa/Cocoa.h>
#import "Camera.h"
#import "Window3DController.h"

@interface FlyThruAdapter : NSObject {
	
	Window3DController	*controller;

}

- (id) initWithWindow3DController: (Window3DController*) aWindow3DController;
- (Camera*) getCurrentCamera;
- (void) setCurrentViewToCamera:(Camera*)aCamera;
- (NSImage*) getCurrentCameraImage:(BOOL) highQuality;
@end
