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

#import "N2AdaptiveBox.h"
#import "N2Operators.h"


@implementation N2AdaptiveBox

-(void)awakeFromNib {
	idealContentSize = NSZeroSize;
}

-(void)adaptContainersToIdealSize:(NSSize)size {
	idealContentSize = size;
	[self adaptContainersToIdealSize];
}

-(void)adaptContainersToIdealSize {
	NSView* view = [self contentView];
	NSSize contentSize = view.frame.size;
	NSSize sizeDelta = idealContentSize - contentSize;
	idealContentSize = NSZeroSize;
	
/*	NSMutableArray* animations = NULL;
	if ([self.window.windowController respondsToSelector:@selector(animations)])
		animations = [self.window.windowController valueForKey:@"animations"];*/

	BOOL hasParentScrollView = NO;
	for (NSView* parentView = [self superview]; !hasParentScrollView && parentView; parentView = [parentView superview])
		if ([parentView isKindOfClass:[NSScrollView class]])
			hasParentScrollView = YES;
	
	if (hasParentScrollView)
		for (NSView* parentView = [self superview]; parentView; parentView = [parentView superview]) {
			if ([parentView isKindOfClass:[NSScrollView class]])
				break;
			NSRect pf = parentView.frame;
			pf.size += sizeDelta;
			pf.origin.y -= sizeDelta.height;
	/*		if (animations)
				[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										   parentView, NSViewAnimationTargetKey,
										   [NSValue valueWithRect:pf], NSViewAnimationEndFrameKey,
									   NULL]];
			else*/ [parentView setFrame:pf];
		}
	else {
		NSRect wf = self.window.frame;
		wf.size += sizeDelta;
		//if (!self.window.isSheet)
			wf.origin.y -= sizeDelta.height;
		[self.window setFrame:wf display:YES];
	}
}

-(void)setContentView:(NSView*)view {
	NSMutableArray* animations = NULL;
	if ([self.window.windowController respondsToSelector:@selector(animations)])
		animations = [self.window.windowController valueForKey:@"animations"];
	
	idealContentSize = view.frame.size;
	/*[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   self.contentView, NSViewAnimationTargetKey,
						   NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
						   NULL]];*/
	[super setContentView:view];
	[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   self, NSViewAnimationTargetKey,
						   NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
						   NULL]];
	if (self.window)
		[self adaptContainersToIdealSize];
}

-(void)viewDidMoveToWindow {
	if (!NSEqualSizes(idealContentSize, NSZeroSize))
		[self adaptContainersToIdealSize];
	[super viewDidMoveToWindow];
}

@end
