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

/** \brief   VR view for Endoscopy
*/

#import <Cocoa/Cocoa.h>

#import "VRView.h"

@interface EndoscopyVRView : VRView {

}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower;

@end
