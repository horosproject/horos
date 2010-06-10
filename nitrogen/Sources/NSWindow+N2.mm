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

#import "NSWindow+N2.h"
#import "N2Operators.h"


@implementation NSWindow (N2)

-(NSSize)contentSizeForFrameSize:(NSSize)frameSize {
	return [self contentRectForFrameRect:NSMakeRect([self frame].origin, frameSize)].size;
}

-(NSSize)frameSizeForContentSize:(NSSize)contentSize {
	return [self frameRectForContentRect:NSMakeRect([self frame].origin, contentSize)].size; // [self frame].origin isnt't correct but that doesnt matter
}

-(CGFloat)toolbarHeight {
	if (![self.toolbar isVisible])
		return 0;
	
	NSRect windowFrame = [NSWindow contentRectForFrameRect:self.frame styleMask:self.styleMask];
	return windowFrame.size.height-NSHeight([[self contentView] frame]);
}

-(CGFloat)titlebarHeight {
	NSRect frame = NSMakeRect(0, 0, 100, 100);
    NSRect contentRect = [NSWindow contentRectForFrameRect:frame styleMask:NSTitledWindowMask];
    return frame.size.height - contentRect.size.height;
}

@end
