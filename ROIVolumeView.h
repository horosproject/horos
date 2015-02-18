/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

	 
	 
	ROIVolumeView creates and displays an ROI Volume created feom a stack of 2D ROIs
=========================================================================*/

#import <AppKit/AppKit.h>
#import "VTKViewOSIRIX.h"
#import "DCMPix.h"
#import "Camera.h"

#define id Id
#include "vtkSphereSource.h"
#include "vtkGlyph3D.h"
#include "vtkSurfaceReconstructionFilter.h"
#include "vtkReverseSense.h"
#include "vtkCommand.h"
#include "vtkShrinkFilter.h"
#include "vtkDelaunay3D.h"
#include "vtkDelaunay2D.h"
#include "vtkProperty.h"
#include "vtkActor.h"
#include "vtkPolyData.h"
#include "vtkRenderer.h"
#include "vtkOrientationMarkerWidget.h"
#include "vtkAnnotatedCubeActor.h"
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
#include "vtkTextProperty.h"
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
#include "vtkCleanPolyData.h"
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
#include "vtkPolyDataNormals.h"
#include "vtkFrustumCoverageCuller.h"
#include "vtkGeometryFilter.h"
#include "vtkTIFFReader.h"
#include "vtkTexture.h"
#include "vtkTextureMapToSphere.h"
#include "vtkTransformTextureCoords.h"
#include "vtkPowerCrustSurfaceReconstruction.h"
#include "vtkTriangleFilter.h"
#undef id

class vtkMyCallback;

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

@class Camera;

/** \brief  View for ROI Volume */

@interface ROIVolumeView : VTKView
{
    vtkRenderer					*aRenderer;
    vtkCamera					*aCamera;
	
//	vtkActor					*ballActor;
	vtkActor					*roiVolumeActor;
	vtkTexture					*texture;
	
    vtkActor					*outlineRect;
    vtkPolyDataMapper			*mapOutline;
    vtkOutlineFilter			*outlineData;
	vtkOrientationMarkerWidget	*orientationWidget;
	
    ROI                         *roi;
	BOOL						computeMedialSurface;

}


- (NSDictionary*) setPixSource: (ROI*) r;
- (void) setROIActorVolume:(NSValue*)roiActorPointer;
- (void) setOpacity: (float) opacity showPoints: (BOOL) sp showSurface: (BOOL) sS showWireframe:(BOOL) w texture:(BOOL) tex useColor:(BOOL) usecol color:(NSColor*) col;
- (IBAction) exportDICOMFile:(id) sender;
- (NSDictionary*) renderVolume;
+ (vtkMapper*) generateMapperForRoi:(ROI*) roi viewerController: (ViewerController*) vc factor: (float) factor statistics: (NSMutableDictionary*) statistics;
- (NSSet *)connectedPointsForPoint:(vtkIdType)pt fromPolyData:(vtkPolyData *)data;

@end
