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

@interface LLScoutView : OrthogonalMPRView {
	int		topLimit, bottomLimit;
	BOOL	isFlipped, 	draggingTopLimit, draggingBottomLimit;
}

- (void)setTopLimit:(int)newLimit;
- (void)setBottomLimit:(int)newLimit;
- (void)setIsFlipped:(BOOL)boo;
- (void)getOpenGLLimitPosition:(float*)positions;
- (void)drawArrowButtonAtPosition:(float)position;
- (NSRect)rectForArrowButtonAtIndex:(int)index;
- (NSRect)rectForLimitAtIndex:(int)index;

@end
