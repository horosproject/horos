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


#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "DCMView.h" 
#import "ROI.h"

//#define id Id
#include <vtkSphereSource.h>
#include <vtkGlyph3D.h>
#include <vtkSurfaceReconstructionFilter.h>
#include <vtkReverseSense.h>
#include <vtkCommand.h>
#include <vtkShrinkFilter.h>
#include <vtkDelaunay3D.h>
#include <vtkDelaunay2D.h>
#include <vtkProperty.h>
#include <vtkActor.h>
#include <vtkPolyData.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkVolume16Reader.h>
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vtkOutlineFilter.h>
#include <vtkImageReader.h>
#include <vtkImageImport.h>
#include <vtkCamera.h>
#include <vtkStripper.h>
#include <vtkLookupTable.h>
#include <vtkImageDataGeometryFilter.h>
#include <vtkProperty.h>
#include <vtkPolyDataNormals.h>
#include <vtkContourFilter.h>
#include <vtkImageData.h>
#include <vtkImageMapToColors.h>
#include <vtkImageActor.h>
#include <vtkLight.h>

#include <vtkPlane.h>
#include <vtkPlanes.h>
#include <vtkPlaneSource.h>
#include <vtkBoxWidget.h>
#include <vtkPlaneWidget.h>
#include <vtkPiecewiseFunction.h>
#include <vtkPiecewiseFunction.h>
#include <vtkColorTransferFunction.h>
#include <vtkVolumeProperty.h>
#include <vtkVolumeRayCastCompositeFunction.h>
#include <vtkVolumeRayCastMapper.h>
#include <vtkVolumeRayCastMIPFunction.h>

#include <vtkTransform.h>
#include <vtkSphere.h>
#include <vtkImplicitBoolean.h>
#include <vtkExtractGeometry.h>
#include <vtkDataSetMapper.h>
#include <vtkPicker.h>
#include <vtkCellPicker.h>
#include <vtkPointPicker.h>
#include <vtkLineSource.h>
#include <vtkPolyDataMapper2D.h>
#include <vtkActor2D.h>
#include <vtkExtractPolyDataGeometry.h>
#include <vtkProbeFilter.h>
#include <vtkCutter.h>
#include <vtkTransformPolyDataFilter.h>
#include <vtkXYPlotActor.h>
#include <vtkClipPolyData.h>
#include <vtkBox.h>
#include <vtkCallbackCommand.h>
#include <vtkImageResample.h>
#include <vtkDecimatePro.h>
#include <vtkSmoothPolyDataFilter.h>
#include <vtkImageFlip.h>
#include <vtkTextActor.h>
#include <vtkPolyDataNormals.h>
#include <vtkFrustumCoverageCuller.h>
#include <vtkGeometryFilter.h>
#include <vtkTIFFReader.h>
#include <vtkTexture.h>
#include <vtkTextureMapToSphere.h>
#include <vtkTransformTextureCoords.h>
//#include "vtkPowerCrustSurfaceReconstruction.h"

//#undef id

/** \brief  creates volume from stack of Brush ROIs */

@class ViewerController;

@interface ROIVolume : NSObject {
	NSMutableArray		*roiList;
	vtkActor			*roiVolumeActor;
	vtkTexture			*textureImage;
	float				volume, red, green, blue, opacity, factor;
	NSColor				*color;
	BOOL				visible, textured;
	NSString			*name;
    ViewerController    *viewer;
	
	NSMutableDictionary		*properties;
}

@property float factor;

- (void) setTexture: (BOOL) o;
- (BOOL) texture;

- (void) setROIList: (NSArray*) newRoiList;
- (void) prepareVTKActor;

- (BOOL) isVolume;
- (NSValue*) roiVolumeActor;
- (BOOL) isRoiVolumeActorComputed;

- (float) volume;

- (NSColor*) color;
- (void) setColor: (NSColor*) c;

- (float) red;
- (void) setRed: (float) r;
- (float) green;
- (void) setGreen: (float) g;
- (float) blue;
- (void) setBlue: (float) b;
- (float) opacity;
- (void) setOpacity: (float) o;

- (float) factor;
- (void) setFactor: (float) f;

- (BOOL) visible;
- (void) setVisible: (BOOL) d;

- (NSString*) name;

- (NSDictionary*) properties;

- (NSMutableDictionary*)displayProperties;
- (void)setDisplayProperties:(NSDictionary*)newProperties;
- (id) initWithViewer: (ViewerController*) v;
@end
