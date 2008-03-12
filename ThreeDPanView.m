/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ThreeDPanView.h"


@implementation ThreeDPanView

- (void)mouseDown:(NSEvent *)theEvent
{
	NSLog( @"mouseDown");
	
	[self setEnabled: YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSLog( @"mouseDragged");
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSLog( @"mouseUp");
	
	[self setEnabled: NO];
}

@end
