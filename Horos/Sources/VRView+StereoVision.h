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
//
// Program:   OsiriX
//
// Created by Silvan Widmer on 8/25/09.
//
// Copyright (c) LIB EPFL
// All rights reserved.
// Distributed under GNU - GPL
//
// See http://www.osirix-viewer.com/copyright.html for details.
//
// This software is distributed WITHOUT ANY WARRANTY; without even
// the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.
// =========================================================================


#ifdef _STEREO_VISION_

#import <Cocoa/Cocoa.h>
#import "VRView.h"
#import <AppKit/AppKit.h>
#import "DCMPix.h"

#ifdef __cplusplus
#import "VTKViewOSIRIX.h"

//#define id Id
#include "vtkCommand.h"
#include "vtkActor.h"
#include "vtkPolyData.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkVolume16Reader.h"
#include "vtkPolyDataMapper.h"
#include "vtkActor.h"
#include "vtkOutlineFilter.h"
#include "vtkImageReader.h"
#include "vtkImageImport.h"
#include "vtkCamera.h"
#include "vtkStripper.h"
#include "vtkLookupTable.h"
#include "vtkImageDataGeometryFilter.h"
#include "vtkProperty.h"
#include "vtkPolyDataNormals.h"
#include "vtkContourFilter.h"
#include "vtkImageData.h"
#include "vtkImageMapToColors.h"
#include "vtkImageActor.h"
#include "vtkLight.h"

#include "vtkPlane.h"
#include "vtkPlanes.h"
#include "vtkPlaneSource.h"
#include "vtkBoxWidget.h"
#include "vtkPiecewiseFunction.h"
#include "vtkPiecewiseFunction.h"
#include "vtkColorTransferFunction.h"
#include "vtkVolumeProperty.h"
#include "vtkVolumeRayCastCompositeFunction.h"
#include "vtkVolumeRayCastMapper.h"
#include "vtkVolumeRayCastMIPFunction.h"
#include "vtkFixedPointVolumeRayCastMapper.h"
#include "vtkTransform.h"
#include "vtkSphere.h"
#include "vtkImplicitBoolean.h"
#include "vtkExtractGeometry.h"
#include "vtkDataSetMapper.h"
#include "vtkPicker.h"
#include "vtkCellPicker.h"
#include "vtkPointPicker.h"
#include "vtkLineSource.h"
#include "vtkPolyDataMapper2D.h"
#include "vtkActor2D.h"
#include "vtkExtractPolyDataGeometry.h"
#include "vtkProbeFilter.h"
#include "vtkCutter.h"
#include "vtkTransformPolyDataFilter.h"
#include "vtkXYPlotActor.h"
#include "vtkClipPolyData.h"
#include "vtkBox.h"
#include "vtkCallbackCommand.h"
#include "vtkTextActor.h"
#include "vtkTextProperty.h"
#include "vtkImageFlip.h"
#include "vtkAnnotatedCubeActor.h"
#include "vtkOrientationMarkerWidget.h"
#include "vtkVolumeTextureMapper2D.h"
#include "vtkVolumeTextureMapper3D.h"
#include "vtkHorosFixedPointVolumeRayCastMapper.h"

#include "vtkCellArray.h"
#include "vtkProperty2D.h"

// Added SilvanWidmer 10-08-09
// ****************************
#import	 "vtkCocoaGLView.h"
#import "Window3DController+StereoVision.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkParallelRenderManager.h"
#include "vtkRendererCollection.h"
#include "vtkCallbackCommand.h"
// ****************************


//#undef id

class vtkMyCallbackVR;

#else
/*
typedef char* vtkTransform;
typedef char* vtkImageActor;
typedef char* vtkImageMapToColors;
typedef char* vtkLookupTable;
typedef char* vtkImageReslice;
typedef char* vtkImageImport;
typedef char* vtkCamera;
typedef char* vtkActor;
typedef char* vtkPolyDataMapper;
typedef char* vtkOutlineFilter;
typedef char* vtkLineWidget;

typedef char* vtkTextActor;
typedef char* vtkVolumeRayCastMapper;
typedef char* vtkFixedPointVolumeRayCastMapper;
typedef char* vtkHorosFixedPointVolumeRayCastMapper;
typedef char* vtkVolumeRayCastMIPFunction;
typedef char* vtkVolume;


typedef char* vtkPiecewiseFunction;
typedef char* vtkVolumeTextureMapper2D;
typedef char* vtkPolyData;
typedef char* vtkVolumeProperty;
typedef char* vtkPolyDataMapper2D;

typedef char* vtkColorTransferFunction;
typedef char* vtkActor2D;
typedef char* vtkMyCallback;
typedef char* vtkBoxWidget;
typedef char* vtkVolumeRayCastCompositeFunction;

typedef char* vtkRenderer;
typedef char* vtkVolumeTextureMapper3D;
typedef char* vtkOrientationMarkerWidget;

typedef char* vtkMyCallbackVR;*/
#endif

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

@class DICOMExport;
@class Camera;
@class VRController;
@class OSIVoxel;

#import "CLUTOpacityView.h"

/** \brief  Volume Rendering View
 *
 *   View for volume rendering and MIP
 */
#ifdef __cplusplus
#else
#define VTKView NSView
#endif


@interface VRView ( StereoVision )

- (short) LeftRightDualScreen;
- (void) LeftRightSingleScreen;
- (void) initStereoLeftRight;
- (void) disableStereoModeLeftRight;
- (void) adjustWindowContent: (NSSize) proposedFrameSize;
- (IBAction) SwitchStereoMode :(id) sender;
- (void) setNewViewAngle: (double) viewAngle;
- (IBAction) invertedSides :(id) sender;
- (short) LeftRightMovieScreen;
- (void) setDisplayStereo3DPoints: (vtkRenderer*) theRenderer: (BOOL) on;
- (void) setNewGeometry: (double) screenHeight: (double) screenDistance: (double) eyeDistance;


@end

#endif
