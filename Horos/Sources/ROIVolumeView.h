/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import <AppKit/AppKit.h>
#import "VTKViewOSIRIX.h"
#import "DCMPix.h"
#import "Camera.h"

//#define id Id
#include <VTK/vtkSphereSource.h>
#include <VTK/vtkGlyph3D.h>
#include <VTK/vtkSurfaceReconstructionFilter.h>
#include <VTK/vtkReverseSense.h>
#include <VTK/vtkCommand.h>
#include <VTK/vtkShrinkFilter.h>
#include <VTK/vtkDelaunay3D.h>
#include <VTK/vtkDelaunay2D.h>
#include <VTK/vtkProperty.h>
#include <VTK/vtkActor.h>
#include <VTK/vtkPolyData.h>
#include <VTK/vtkRenderer.h>
#include <VTK/vtkOrientationMarkerWidget.h>
#include <VTK/vtkAnnotatedCubeActor.h>
#include <VTK/vtkRenderWindow.h>
#include <VTK/vtkRenderWindowInteractor.h>
#include <VTK/vtkVolume16Reader.h>
#include <VTK/vtkPolyDataMapper.h>
#include <VTK/vtkActor.h>
#include <VTK/vtkOutlineFilter.h>
#include <VTK/vtkImageReader.h>
#include <VTK/vtkImageImport.h>
#include <VTK/vtkCamera.h>
#include <VTK/vtkStripper.h>
#include <VTK/vtkLookupTable.h>
#include <VTK/vtkImageDataGeometryFilter.h>
#include <VTK/vtkProperty.h>
#include <VTK/vtkPolyDataNormals.h>
#include <VTK/vtkContourFilter.h>
#include <VTK/vtkImageData.h>
#include <VTK/vtkImageMapToColors.h>
#include <VTK/vtkImageActor.h>
#include <VTK/vtkLight.h>
#include <VTK/vtkTextProperty.h>
#include <VTK/vtkPlane.h>
#include <VTK/vtkPlanes.h>
#include <VTK/vtkPlaneSource.h>
#include <VTK/vtkBoxWidget.h>
#include <VTK/vtkPlaneWidget.h>
#include <VTK/vtkPiecewiseFunction.h>
#include <VTK/vtkPiecewiseFunction.h>
#include <VTK/vtkColorTransferFunction.h>
#include <VTK/vtkVolumeProperty.h>
#include <VTK/vtkVolumeRayCastCompositeFunction.h>
#include <VTK/vtkVolumeRayCastMapper.h>
#include <VTK/vtkVolumeRayCastMIPFunction.h>
#include <VTK/vtkCleanPolyData.h>
#include <VTK/vtkTransform.h>
#include <VTK/vtkSphere.h>
#include <VTK/vtkImplicitBoolean.h>
#include <VTK/vtkExtractGeometry.h>
#include <VTK/vtkDataSetMapper.h>
#include <VTK/vtkPicker.h>
#include <VTK/vtkCellPicker.h>
#include <VTK/vtkPointPicker.h>
#include <VTK/vtkLineSource.h>
#include <VTK/vtkPolyDataMapper2D.h>
#include <VTK/vtkActor2D.h>
#include <VTK/vtkExtractPolyDataGeometry.h>
#include <VTK/vtkProbeFilter.h>
#include <VTK/vtkCutter.h>
#include <VTK/vtkTransformPolyDataFilter.h>
#include <VTK/vtkXYPlotActor.h>
#include <VTK/vtkClipPolyData.h>
#include <VTK/vtkBox.h>
#include <VTK/vtkCallbackCommand.h>
#include <VTK/vtkImageResample.h>
#include <VTK/vtkDecimatePro.h>
#include <VTK/vtkSmoothPolyDataFilter.h>
#include <VTK/vtkImageFlip.h>
#include <VTK/vtkTextActor.h>
#include <VTK/vtkPolyDataNormals.h>
#include <VTK/vtkFrustumCoverageCuller.h>
#include <VTK/vtkGeometryFilter.h>
#include <VTK/vtkTIFFReader.h>
#include <VTK/vtkTexture.h>
#include <VTK/vtkTextureMapToSphere.h>
#include <VTK/vtkTransformTextureCoords.h>
//#include "vtkPowerCrustSurfaceReconstruction.h"
#include <VTK/vtkTriangleFilter.h>
//#undef id

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
