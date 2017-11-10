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
#import "OrthogonalMPRController.h"

@class LLMPRView;

@interface LLMPRController : OrthogonalMPRController {
	NSRange		pixListRange;
}

- (void)resliceFromNotification: (NSNotification*)notification;
- (void)shiftView:(OrthogonalMPRView*)view x:(int)deltaX y:(int)deltaY;
- (void)removeBonesAtX:(int)x y:(int)y fromView:(LLMPRView*)view;
- (void)setPixListRange:(NSRange)range;

@end
