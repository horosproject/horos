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




#import <Cocoa/Cocoa.h>
#import "FlyThruAdapter.h"

@class SRController;

/** \brief FlyThruAdapter for Surface Rendering
*
* Surface Rendering FlyThruAdapter
*/

@interface SRFlyThruAdapter : FlyThruAdapter {

}

- (id) initWithSRController: (SRController*) aSRController;

@end
