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
#import "OrthogonalMPRView.h"

/** \brief OrthogonalMPRView for PET-CT fusion */

@interface OrthogonalMPRPETCTView : OrthogonalMPRView {
}
- (void) superSetBlendingFactor:(float) f;
- (void) superFlipVertical:(id) sender;
- (void) superFlipHorizontal:(id) sender;

@end
