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

#import "ThreeDPanView.h"


@implementation ThreeDPanView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)setController: (ThreeDPositionController*) c
{
	controller = c;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[self setEnabled: YES];
	
	mouseDownPoint = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	float move[ 3];
	
	switch( [self tag])
	{
		case 0:
			switch( [controller mode])
			{
				case 0:		// Axial
					move[ 0] = (mouseDownPoint.x - [theEvent locationInWindow].x);
					move[ 1] = -(mouseDownPoint.y - [theEvent locationInWindow].y);
					move[ 2] = 0;
				break;
				
				case 1:		// Coronal
					move[ 0] = (mouseDownPoint.x - [theEvent locationInWindow].x);
					move[ 1] = 0;
					move[ 2] = -(mouseDownPoint.y - [theEvent locationInWindow].y);
				break;
				
				case 2:		// Sag
					move[ 0] = 0;
					move[ 1] = (mouseDownPoint.x - [theEvent locationInWindow].x);
					move[ 2] = -(mouseDownPoint.y - [theEvent locationInWindow].y);
				break;
			}
		break;
		
		case 1:
			switch( [controller mode])
			{
				case 0:		// Axial
					move[ 0] = (mouseDownPoint.x - [theEvent locationInWindow].x);
					move[ 1] = 0;
					move[ 2] = -(mouseDownPoint.y - [theEvent locationInWindow].y);
				break;
				
				case 1:		// Coronal
					move[ 0] = (mouseDownPoint.x - [theEvent locationInWindow].x);
					move[ 1] = -(mouseDownPoint.y - [theEvent locationInWindow].y);
					move[ 2] = 0;
				break;
				
				case 2:		// Sag
					move[ 0] = (mouseDownPoint.x - [theEvent locationInWindow].x);
					move[ 1] = -(mouseDownPoint.y - [theEvent locationInWindow].y);
					move[ 2] = 0;
				break;
			}
		break;
	}
		
	move[ 0] /= 2.;
	move[ 1] /= 2.;
	move[ 2] /= 2.;
	
	[controller movePositionPosition: move];
	
	mouseDownPoint = [theEvent locationInWindow];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[self setEnabled: NO];
}

@end
