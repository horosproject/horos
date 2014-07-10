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


#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

//#import	"VRView+StereoVision.h"
#ifdef __cplusplus
#import "vtkCocoaGLView.h"
#import "VTKView.h"


//#import "vtkCocoaWindow.h"
#define id Id
#include "vtkCamera.h"

#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"

#undef id
#else
typedef char* vtkCocoaWindow;
typedef char* vtkRenderer;
typedef char* vtkRenderWindow;
typedef char* vtkRenderWindowInteractor;
typedef char* vtkCocoaRenderWindowInteractor;
typedef char* vtkCocoaRenderWindow;
typedef char* vtkCamera;

#endif

@class VRView;

@interface VTKStereoVRView : VTKView {
	
	NSCursor					*cursor;
	BOOL						cursorSet;

	VRView						*superVRView;
	
}

//-(id)initWithFrame:(NSRect)frame;
-(id)initWithFrame:(NSRect)frame: (VRView*) aView;
//- (void) convert3Dto2Dpoint:(double*) pt3D :(double*) pt2D;
//- (void)deleteMouseDownTimer;
//- (void)deleteRightMouseDownTimer;
//- (long) getTool: (NSEvent*) event;
//-(void) setCursorForView: (ToolMode) tool;
//-(void) setCurrentTool:(ToolMode) i;
//- (void) flagsChanged:(NSEvent *)event;
//- (void) unselectAllActors;
//- (void) updateProjectionMode: (int) i;
//- (void) unselectAllActors;


@end
#endif