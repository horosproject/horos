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



#define id Id
#include "vtkRenderer.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCommand.h"
#include "vtkCamera.h"
#include "vtkInteractorStyleTrackballCamera.h"
#undef id

//#import "vtkCocoaWindow.h"
//#import "vtkCocoaWindowModifications.h"
#import "VTKView.h"


@implementation VTKView

-(vtkCocoaRenderWindow *) cocoaWindow
{
    return _cocoaRenderWindow;
}

-(id)initWithFrame:(NSRect)frame {

    if ( self = [super initWithFrame:frame])
	{
        _renderer = vtkRenderer::New();
		_cocoaRenderWindow = vtkCocoaRenderWindow::New();
		_cocoaRenderWindow->SetWindowId( [self window]);
		_cocoaRenderWindow->SetDisplayId( self);
		NSLog( @"%s", _cocoaRenderWindow->GetWindowName());
		
		_cocoaRenderWindow->AddRenderer(_renderer);
        _interactor = vtkCocoaRenderWindowInteractor::New();
		_interactor->SetRenderWindow(_cocoaRenderWindow);
		
		vtkInteractorStyleTrackballCamera *interactorStyle;
		interactorStyle = vtkInteractorStyleTrackballCamera::New();
		_interactor->SetInteractorStyle( interactorStyle );
		interactorStyle->Delete();
		
        [self setVTKRenderWindow:_cocoaRenderWindow];
        
        _interactor->Initialize();
     }
    
    return self;
}

-(void)dealloc
{
    _renderer->Delete();
	_cocoaRenderWindow->Delete();
	_interactor->Delete();
	[super dealloc];
}

- (void) prepareForRelease
{
	_cocoaRenderWindow->SetWindowId( 0L);
	_cocoaRenderWindow->SetDisplayId( 0L);
}

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}


- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];

	if (c != 'q' && c!= 'e')						// Don't forward to super if Q or E key pressed: DDP (051112,051128)
		[super keyDown: event];
}



-(vtkRenderer *)renderer {
    return _renderer;
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
