//
//  LLScoutView.h
//  OsiriX
//
//  Created by Joris Heuberger on 18/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

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
