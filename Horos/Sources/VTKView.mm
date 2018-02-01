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


#include "options.h"

//#define id Id
#include <vtkRenderer.h>
#include <vtkCocoaRenderWindow.h>
#include <vtkCocoaRenderWindowInteractor.h>
#include <vtkCommand.h>
#include <vtkCamera.h>
#include <vtkInteractorStyleTrackballCamera.h>
#include <vtkOpenGLRenderer.h>
//#undef id

#import "VTKViewOSIRIX.h"

#import "DefaultsOsiriX.h"

@implementation VTKView



-(id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self initializeVTKSupport];
    }
     return self;
}


-(void)dealloc
{
	NSLog( @"VTKView dealloc");
  
    [self cleanUpVTKSupport];
    [super dealloc];
}


// We are going to over ride the super class here to do some last minute
// setups. We need to do this because if we initialize in the constructor or
// even later, in say an NSDocument's windowControllerDidLoadNib, then
// we will get a warning about "Invalid Drawable" because the OpenGL Context
// is trying to be set and rendered into an NSView that most likely is not
// on screen yet. This is a way to defer that initialization until the NSWindow
// that contains our NSView subclass is actually on screen and ready to be drawn.
- (void)drawRect:(NSRect)theRect
{
    // Check for a valid vtkWindowInteractor and then initialize it. Technically we
    // do not need to do this, but what happens is that the window that contains
    // this object will not immediately render it so you end up with a big empty
    // space in your gui where this NSView subclass should be. This may or may
    // not be what is wanted. If you allow this code then what you end up with is the
    // typical empty black OpenGL view which seems more 'correct' or at least is
    // more soothing to the eye.
    vtkRenderWindowInteractor* theRenWinInt = [self getInteractor];
    if (theRenWinInt && (theRenWinInt->GetInitialized() == NO))
    {
        theRenWinInt->Initialize();
    }
    
    // Let the vtkCocoaGLView do its regular drawing
    [super drawRect:theRect];
}

- (void)initializeVTKSupport
{
    // The usual vtk object creation
    vtkRenderer* ren = vtkRenderer::New();
    vtkRenderWindow* renWin = vtkRenderWindow::New();
    vtkRenderWindowInteractor* renWinInt = vtkRenderWindowInteractor::New();
    
    
    vtkInteractorStyleTrackballCamera *interactorStyle =
                                           vtkInteractorStyleTrackballCamera::New();
    	renWinInt->SetInteractorStyle( interactorStyle );
    		interactorStyle->Delete();
    
    // The cast should never fail, but we do it anyway, as
    // it's more correct to do so.
    _cocoaRenderWindow = vtkCocoaRenderWindow::SafeDownCast(renWin);
    
    if (ren && _cocoaRenderWindow && renWinInt)
    {
        // This is special to our usage of vtk.  To prevent vtk
        // from creating an NSWindow and NSView automatically (its
        // default behaviour) we tell vtk that they exist already.
        // The APIs names are a bit misleading, due to the cross
        // platform nature of vtk, but this usage is correct.
        _cocoaRenderWindow->SetRootWindow([self window]);
        _cocoaRenderWindow->SetWindowId(self);
        
        // The usual vtk connections
        _cocoaRenderWindow->AddRenderer(ren);
        renWinInt->SetRenderWindow(_cocoaRenderWindow);
        
        // This is special to our usage of vtk.  vtkCocoaGLView
        // keeps track of the renderWindow, and has a get
        // accessor if you ever need it.
        [self setVTKRenderWindow:_cocoaRenderWindow];
        
        // Likewise, BasicVTKView keeps track of the renderer
        [self setRenderer:ren];
    }
}

- (void)cleanUpVTKSupport
{
    vtkRenderer* ren = [self renderer];
    vtkRenderWindow* renWin = [self getVTKRenderWindow];
    vtkRenderWindowInteractor* renWinInt = [self getInteractor];
    
    if (ren)
    {
        ren->Delete();
    }
    if (renWin)
    {
        renWin->Delete();
    }
    if (renWinInt)
    {
        renWinInt->Delete();
    }
    [self setRenderer:NULL];
    [self setVTKRenderWindow:NULL];
    
    // There is no setter accessor for the render window
    // interactor, that's ok.
}

- (void) prepareForRelease // VTK memory leak
{
	_cocoaRenderWindow->SetWindowId( nil);
    _cocoaRenderWindow->SetRootWindow(nil);
}

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

//#include "vtkGPUInfoList.h"
//#include "vtkGPUInfo.h"
// Return result in MB
+ (unsigned long) VRAMSizeForDisplayID: (CGDirectDisplayID) displayID
{
    return [DefaultsOsiriX GPUModelVRAMInfo];
}

- (void) keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;

    unichar c = [[event characters] characterAtIndex:0];

	if (c != 'q' && c!= 'e')						// Don't forward to super if Q or E key pressed: DDP (051112,051128)
		[super keyDown: event];
}



-(vtkRenderer *)renderer {
    return _renderer;
}

- (void)setRenderer:(vtkRenderer*)theRenderer
{
    _renderer = theRenderer;
}

-(vtkCocoaRenderWindow *) cocoaWindow
{
    return _cocoaRenderWindow;
}

-(vtkRenderWindow *)renderWindow {
    return [self getVTKRenderWindow];
}


-(void)removeAllActors {
    vtkRenderer *renderer = [self renderer];
    if ( ! renderer ) return;

    vtkActorCollection *coll = renderer->GetActors();
    coll->RemoveAllItems();
}

@end
