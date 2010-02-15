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

#import <N2Window.h>
#import <N2View.h>
#import <N2Operators.h>


@implementation NSWindow (N2)

-(NSSize)contentSizeForFrameSize:(NSSize)frameSize {
	return [self contentRectForFrameRect:NSMakeRect([self frame].origin, frameSize)].size;
}

-(NSSize)frameSizeForContentSize:(NSSize)contentSize {
	return [self frameRectForContentRect:NSMakeRect([self frame].origin, contentSize)].size; // [self frame].origin isnt't correct but that doesnt matter
}

@end


@implementation N2Window

-(id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
	self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
	[self setContentView:[[N2View alloc] initWithFrame:[[self contentView] frame]]];
	return self;
}

@end
