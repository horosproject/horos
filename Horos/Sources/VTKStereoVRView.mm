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

#import "VTKStereoVRView.h"
#import "VTKViewOSIRIX.h"
#import "DCMView.h"
#import "DCMCursor.h"
#import "Notifications.h"
#import "VRView.h"

//#define id Id
#include "vtkRenderer.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCommand.h"
#include "vtkCamera.h"
#include "vtkInteractorStyleTrackballCamera.h"
//#undef id

static NSRecursiveLock *drawLock = nil;


@implementation VTKStereoVRView

-(id)initWithFrame:(NSRect)frame: (VRView*) aView
{
	if (self = [super initWithFrame:frame])
	{
		
		superVRView = aView;
		NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil] autorelease];
		
		[self addTrackingArea: cursorTracking];
		
//		aRenderer = [self renderer];
//		cursor = nil;
//		currentTool = t3DRotate;
//		isViewportResizable = NO;
//		[self setCursorForView: currentTool];
		
//		if( drawLock == nil) drawLock = [[NSRecursiveLock alloc] init];
		
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
	superVRView = nil;
	[superVRView release];

//	snVRView = nil;
//	[snVRView release];
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
	[superVRView mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[superVRView mouseExited:theEvent];
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    [superVRView cursorUpdate:theEvent];
}

- (void) checkCursor
{
	if(cursorSet) [cursor set];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[superVRView mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{ssss
	[superVRView rightMouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent{
	[superVRView mouseDragged:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent{
	[superVRView rightMouseDragged:theEvent];
}
- (void)otherMouseDown:(NSEvent *)theEvent
{
	[superVRView otherMouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent{
	[superVRView mouseUp:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent{
	[superVRView rightMouseUp:theEvent];
}

- (void) scrollWheel:(NSEvent *)theEvent
{
	[superVRView scrollWheel:theEvent];
}

-(void) mouseMoved: (NSEvent*) theEvent
{
	if( ![[self window] isVisible])
		return;
	
	[superVRView mouseMoved:theEvent];
}

- (void)zoomMouseUp:(NSEvent *)theEvent{
	[superVRView zoomMouseUp:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
	[superVRView keyDown:theEvent];
}
@end

#endif
