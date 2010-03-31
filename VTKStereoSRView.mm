#ifdef _STEREO_VISION_
//
//  VTKStereoView.m
//  OsiriX
//
//  Created by Silvan Widmer on 3/15/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "VTKStereoSRView.h"
#import "VTKView.h"
#import "DCMView.h"
#import "DCMCursor.h"
#import "Notifications.h"
#import "SRView.h"

#define id Id
#include "vtkRenderer.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCommand.h"
#include "vtkCamera.h"
#include "vtkInteractorStyleTrackballCamera.h"
#undef id



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