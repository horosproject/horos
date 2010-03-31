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
#import "SRView.h"

#import <AppKit/AppKit.h>

#import "DCMPix.h"
#import "Camera.h"

#ifdef __cplusplus
#import "VTKView.h"
#define id Id
#include "vtkCommand.h"
#include "vtkProperty.h"
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
#include "vtkPlaneWidget.h"
#include "vtkPiecewiseFunction.h"
#include "vtkPiecewiseFunction.h"
#include "vtkColorTransferFunction.h"
#include "vtkVolumeProperty.h"
#include "vtkVolumeRayCastCompositeFunction.h"
#include "vtkVolumeRayCastMapper.h"
#include "vtkVolumeRayCastMIPFunction.h"

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
#include "vtkImageResample.h"
#include "vtkDecimatePro.h"
#include "vtkSmoothPolyDataFilter.h"
#include "vtkImageFlip.h"
#include "vtkTextActor.h"
#include "vtkAnnotatedCubeActor.h"
#include "vtkOrientationMarkerWidget.h"
#include "vtkTextProperty.h"

// Added SilvanWidmer 10-08-09
// ****************************
#import	 "vtkCocoaGLView.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkParallelRenderManager.h"
#include "vtkRendererCollection.h"
#include "vtkCallbackCommand.h"
// ****************************

#undef id

class vtkMyCallback;

#endif

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

@class Camera;
@class SRController;
@class DICOMExport;


@interface SRView ( StereoVision )

- (id) initWithFrame:(NSRect)frame;
- (void) LeftRightSingleScreen;
- (void) dealloc;
- (void) initStereoLeftRight;
- (short) LeftRightDualScreen;
- (void) setDisplayStereo3DPoints: (vtkRenderer*) theRenderer: (BOOL) on;
- (void) disableStereoModeLeftRight;
- (void) adjustWindowContent: (NSSize) proposedFrameSize;
- (short) LeftRightMovieScreen;
- (NSImage*) nsimageQuicktime;
- (unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
- (IBAction)changeColor:(id)sender;
- (IBAction) endQuicktimeSettings:(id) sender;
- (void) toggleDisplay3DPoints;
- (IBAction) endQuicktimeVRSettings:(id) sender;
- (void) keyDown:(NSEvent *)event;
- (void) remove3DPointAtIndex: (unsigned int) index;
- (void) hideAnnotationFor3DPointAtIndex:(unsigned int) index;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)rightMouseUp:(NSEvent *)theEvent;
- (void) add3DPointActor: (vtkActor*) actor;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)rightMouseDragged:(NSEvent *)theEvent;
- (IBAction) invertedSides :(id) sender;
- (void) updateStereoLeftRight;
- (void) setNewGeometry: (double) screenHeight: (double) screenDistance: (double) eyeDistance;


@end

#endif