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

#define testMPR

#ifdef testMPR
#import "VRMPRView.h"
#else
#import "VRView.h"
#endif

/** \brief   VRview for Endoscopy
*/
#ifdef testMPR
@interface EndoscopyVRView : VRMPRView {
#else
@interface EndoscopyVRView : VRView {
#endif

}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower;
-(unsigned char*) superGetRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
@end
