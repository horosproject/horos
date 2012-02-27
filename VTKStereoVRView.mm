#ifdef _STEREO_VISION_
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


#import "VTKStereoVRView.h"
#import "VTKView.h"
#import "DCMView.h"
#import "DCMCursor.h"
#import "Notifications.h"
#import "VRView.h"

#define id Id
#include "vtkRenderer.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCommand.h"
#include "vtkCamera.h"
#include "vtkInteractorStyleTrackballCamera.h"
#undef id

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