/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "N2AdaptiveBox.h"
#import "N2Operators.h"


@implementation N2AdaptiveBox

-(void)awakeFromNib {
	idealContentSize = NSZeroSize;
}

-(NSAnimation*)adaptContainersToIdealSize:(NSSize)size {
	idealContentSize = size;
	return [self adaptContainersToIdealSize];
}

#define NSRectCenter(r) (r.origin+r.size/2)

-(NSAnimation*)adaptContainersToIdealSize {
	NSAnimation* ret = NULL;
	
	NSView* view = [self contentView];
	NSSize contentSize = view.frame.size;
	NSSize sizeDelta = idealContentSize - contentSize;
	
//	NSLog(@"adaptContainersToIdealSize with contentSize [%f,%f], idealContentSize [%f,%f], sizeDelta [%f,%f]", contentSize.width, contentSize.height, idealContentSize.width, idealContentSize.height, sizeDelta.width, sizeDelta.height);

	idealContentSize = NSZeroSize;

	NSMutableArray* animations = NULL;
	if ([self.window.windowController respondsToSelector:@selector(animations)])
		animations = [self.window.windowController valueForKey:@"animations"];
	
	NSMutableDictionary* autoresizingMasks = [NSMutableDictionary dictionary];
	
	NSScrollView* parentScrollView = NULL;
	NSView* parentChildView = self;
	for (NSView* parentView = [self superview]; !parentScrollView && parentView; parentView = [parentView superview]) {
		NSPoint parentChildViewCenter = NSRectCenter(parentChildView.frame);
		
		if ([parentView isKindOfClass:[NSScrollView class]])
			parentScrollView = (NSScrollView*)parentView;
		else
			for (NSView* view in [parentView subviews]) {
				[autoresizingMasks setObject:[NSNumber numberWithUnsignedInteger:view.autoresizingMask] forKey:[NSValue valueWithPointer:view]];
				if (view == parentChildView)
					view.autoresizingMask = NSViewWidthSizable+NSViewHeightSizable;
				else {
					NSPoint viewCenter = NSRectCenter(view.frame);
					NSUInteger autoresizingMask = view.autoresizingMask&(NSViewMinXMargin+NSViewWidthSizable+NSViewMaxXMargin);
					if (viewCenter.y < parentChildViewCenter.y)
						autoresizingMask |= NSViewMaxYMargin;
					if (viewCenter.y > parentChildViewCenter.y)
						autoresizingMask |= NSViewMinYMargin;
					//	if (viewCenter.x < parentChildViewCenter.x)
					//		autoresizingMask |= NSViewMaxXMargin;
					//	if (viewCenter.x > parentChildViewCenter.x)
					//		autoresizingMask |= NSViewMinXMargin;
					view.autoresizingMask = autoresizingMask;
				}
			}
		
		parentChildView = parentView;
	}
	
	if (parentScrollView) {
		NSRect df = [parentScrollView.documentView frame];
		df.size += sizeDelta;
//		df.origin.y -= sizeDelta.height;
		
		if (animations)
			[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								   parentScrollView.documentView, NSViewAnimationTargetKey,
								   [NSValue valueWithRect:df], NSViewAnimationEndFrameKey,
								   NULL]];
		else [parentScrollView.documentView setFrame:df];
		
		ret = [self.window.windowController synchronizeSizeWithContent];
	} else {
		NSRect wf = self.window.frame;
		wf.size += sizeDelta;
		wf.origin.y -= sizeDelta.height;
		[self.window setFrame:wf display:YES];
	}
	
//	NSLog(@"\tsize is now [%f,%f]", view.frame.size.width, view.frame.size.height);

	for (NSValue* key in autoresizingMasks)
		[(NSView*)[key pointerValue] setAutoresizingMask:[[autoresizingMasks objectForKey:key] unsignedIntegerValue]];
	
	return ret;
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
	
	[super setContentView:[[[NSView alloc] initWithFrame:view.frame] autorelease]];
	
	if (self.window)
		[self adaptContainersToIdealSize];
	
	[super setContentView:view];
		
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.contentView];

//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tempFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.contentView];
	
/*	[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   self, NSViewAnimationTargetKey,
						   NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
						   NULL]];*/
	
}




/*
-(void)tempFrameDidChange:(NSNotification*)n {
	NSView* v = n.object;
	NSLog(@"%@ frameDidChange to [%f,%f]", v, v.frame.size.width, v.frame.size.height);
	v = NULL;
}
*/

-(void)viewDidMoveToWindow {
//	NSLog(@"%@ viewDidMoveToWindow:%@ sized [%f,%f]", self, self.window, self.window.frame.size.width, self.window.frame.size.height);
	if (self.window && !NSEqualSizes(idealContentSize, NSZeroSize))
		[self adaptContainersToIdealSize];
	[super viewDidMoveToWindow];
}

@end

@implementation NSWindowController (N2AdaptiveBox)

-(NSAnimation*)synchronizeSizeWithContent {
	return NULL;
}

@end

