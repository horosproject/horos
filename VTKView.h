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



#import <AppKit/AppKit.h>

#ifdef __cplusplus
#import "vtkCocoaGLView.h"
//#import "vtkCocoaWindow.h"
#define id Id
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
#endif


/** \brief View for using VTK */
@interface VTKView : vtkCocoaGLView
{
    vtkCocoaRenderWindow			*_cocoaRenderWindow;
    vtkRenderer						*_renderer;
    vtkCocoaRenderWindowInteractor	*_interactor;
}

-(id)initWithFrame:(NSRect)frame;
-(void)dealloc;

// Access to VTK instances
-(vtkRenderer *)renderer;
-(vtkRenderWindow *)renderWindow;
-(vtkCocoaRenderWindow *) cocoaWindow;
-(void)removeAllActors;
-(void) prepareForRelease;

@end
