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

#import "OSIWindow.h"

static BOOL dontConstrainWindow = NO;

@implementation OSIWindow

+ (void) setDontConstrainWindow: (BOOL) v
{
	dontConstrainWindow = v;
}

- (NSRect) constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
	if( dontConstrainWindow)
		return frameRect;
	
	return [super constrainFrameRect: frameRect toScreen: screen]; 
}

- (void) dealloc
{
    NSLog( @"OSIWindow dealloc");
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
    [super dealloc];
}

@end
