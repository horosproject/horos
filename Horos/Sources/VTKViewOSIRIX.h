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
/*=========================================================================
 Program:   OsiriX

 Copyright (c) Pixmeo
 All rights reserved.
 =========================================================================*/

#ifndef _VTKVIEWOSIRIX_H_INCLUDED_
#define _VTKVIEWOSIRIX_H_INCLUDED_

#import "options.h"

#include <vtkAutoInit.h>
VTK_MODULE_INIT(vtkRenderingOpenGL2);
VTK_MODULE_INIT(vtkRenderingVolumeOpenGL2);
VTK_MODULE_INIT(vtkRenderingFreeType);

#import <AppKit/AppKit.h>

#ifdef __cplusplus
#import <vtkCocoaGLView.h>
//#define id Id
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkCocoaRenderWindowInteractor.h>
#include <vtkCocoaRenderWindow.h>
//#undef id
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
}

+ (unsigned long) VRAMSizeForDisplayID: (CGDirectDisplayID) displayID;

-(id)initWithFrame:(NSRect)frame;
-(void)dealloc;

// Access to VTK instances
-(vtkRenderer *)renderer;
-(vtkRenderWindow *)renderWindow;
-(vtkCocoaRenderWindow *) cocoaWindow;
-(void)removeAllActors;
-(void) prepareForRelease;

- (void)initializeVTKSupport;
- (void)cleanUpVTKSupport;

// Accessors
- (void)setRenderer:(vtkRenderer*)theRenderer;

@end

#endif
