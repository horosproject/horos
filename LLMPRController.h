//
//  LLMPRController.h
//  OsiriX
//
//  Created by Joris Heuberger on 08/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

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
