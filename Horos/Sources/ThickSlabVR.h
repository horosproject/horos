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
 OsirX project.
 
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




#import <Foundation/Foundation.h>

#import "VTKViewOSIRIX.h"
//#define id Id
#include <VTK/vtkCommand.h>
#include <VTK/vtkProperty.h>
#include <VTK/vtkActor.h>
#include <VTK/vtkPolyData.h>
#include <VTK/vtkRenderer.h>
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
#include <VTK/vtkImageFlip.h>
//#undef id

#include <Accelerate/Accelerate.h>


/** \brief View for Thick Slab Volume Rendering */
@interface ThickSlabVR : NSView {
	float								*imageBlendingPtr, *imagePtr;
	long								width, height, count;
	float								spaceX, spaceY, thickness, ww, wl;
	
	BOOL								flipData, lowQuality;

	float								tableFloatR[256], tableFloatG[256], tableFloatB[256];
	float								tableBlendingFloatR[256], tableBlendingFloatG[256], tableBlendingFloatB[256];
	float								opacityTable[ 256];
	
	vtkVolumeRayCastMapper				*volumeMapper;
	vtkVolume							*volume;
	vtkVolumeProperty					*volumeProperty;
	vtkColorTransferFunction			*colorTransferFunction;
	vtkImageImport						*reader;
	vtkVolumeRayCastCompositeFunction   *compositeFunction;
	vtkPiecewiseFunction				*opacityTransferFunction;
	vtkImageFlip						*flipReader;
	
	vImage_Buffer						srcf, dst8;
	vImage_Buffer						srcfBlending, dst8Blending;
	
    vtkRenderer							*aRenderer;
    vtkCamera							*aCamera;
	
	float								*dstFloatR, *dstFloatG, *dstFloatB;
	long								ifrom, ito, isize;
	BOOL								isRGB;
	
	NSLock								*processorsLock;
	volatile int						numberOfThreadsForCompute;
}
-(void) setImageData:(long) w :(long) h :(long) c :(float) sX :(float) sY :(float) t :(BOOL) flip;
-(void) setWLWW: (float) l :(float) w;
-(void) setBlendingWLWW: (float) l :(float) w;
-(void) setCLUT: (unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(unsigned char*) renderSlab;
-(void) setImageSource: (float*) i :(long) c;
-(void) setFlip: (BOOL) f;
- (void) setLowQuality:(BOOL) q;
-(void) setOpacity:(NSArray*) array;
-(void) setImageBlendingSource: (float*) i;
@end
