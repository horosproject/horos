#ifdef _STEREO_VISION_
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

#import <Cocoa/Cocoa.h>
#import "VRView.h"
#import <AppKit/AppKit.h>
#import "DCMPix.h"

#ifdef __cplusplus
#import "VTKView.h"

#define id Id
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
#include "OsiriXFixedPointVolumeRayCastMapper.h"

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


#undef id

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
typedef char* OsiriXFixedPointVolumeRayCastMapper;
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