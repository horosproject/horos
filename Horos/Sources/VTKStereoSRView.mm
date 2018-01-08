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

#ifdef _STEREO_VISION_

#import "VTKStereoSRView.h"
#import "VTKViewOSIRIX.h"
#import "DCMView.h"
#import "DCMCursor.h"
#import "Notifications.h"
#import "SRView.h"

//#define id Id
#include "vtkRenderer.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCommand.h"
#include "vtkCamera.h"
#include "vtkInteractorStyleTrackballCamera.h"
//#undef id



@implementation VTKStereoSRView

-(id)initWithFrame:(NSRect)frame: (SRView*) aSRView;
{
	if (self = [super initWithFrame:frame])
	{
		
		NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil] autorelease];
		
		superSRView = aSRView;
		[self addTrackingArea: cursorTracking];


	//	aRenderer = [self renderer];
	//	cursor = nil;
	//	currentTool = t3DRotate;
	//	[self setCursorForView: currentTool];
	
	}
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
		[[self window] setAcceptsMouseMovedEvents: NO];
		
		[[NSNotificationCenter defaultCenter] removeObserver: self];
	}
}

- (void) dealloc
{
	superSRView = nil;
	[superSRView release];
	/*	
	[cursor release];
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];*/
	
	[super dealloc];
}

#pragma mark-
#pragma mark Cursors

//cursor methods

- (void)mouseEntered:(NSEvent *)theEvent
{
	[superSRView mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[superSRView mouseExited:theEvent];
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    [superSRView cursorUpdate:theEvent];
}


- (void)mouseDown:(NSEvent *)theEvent
{
	[superSRView mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{	
	[superSRView rightMouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent{
	
	[superSRView mouseDragged:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent{
	[superSRView rightMouseDragged:theEvent];
}


- (void)otherMouseDown:(NSEvent *)theEvent
{
	[superSRView otherMouseDown:theEvent];
}


- (void)mouseUp:(NSEvent *)theEvent{
	[superSRView mouseUp:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent{
	[superSRView rightMouseUp:theEvent];
	
}


- (void) keyDown:(NSEvent *)event
{
	[superSRView keyDown:event];
}



@end

#endif
