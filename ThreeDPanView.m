/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
