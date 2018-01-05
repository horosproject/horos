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
 =========================================================================
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
#import "DCMPix.h"
#import "ViewerController.h"

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
#include "vtkImplicitPlaneWidget.h"
#include "vtkImagePlaneWidget.h"
#include "vtkImageBlend.h"
#include "vtkImageReslice.h"
#include "vtkTransform.h"
#include "vtkImageResample.h"
#include "vtkTransformPolyDataFilter.h"
#include "vtkSphereSource.h"
#include "vtkPolyDataToImageStencil.h"
#include "vtkLineWidget.h"
#include "vtkActor2D.h"
#include "vtkMapper2D.h"
#include "vtkPicker.h"
#include "vtkPointPicker.h"
#include "vtkImageChangeInformation.h"
#undef id
#else
typedef char* vtkTransform;
typedef char* vtkImageActor;
typedef char* vtkImageMapToColors;
typedef char* vtkLookupTable;
typedef char* vtkImageReslice;
typedef char* vtkImageImport;
typedef char* vtkRenderer;
typedef char* vtkCamera;
typedef char* vtkActor;
typedef char* vtkPolyDataMapper;
typedef char* vtkOutlineFilter;
typedef char* vtkLineWidget;
typedef char* vtkImageChangeInformation;
#endif

#import "ThickSlabController.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

enum {
	fovMaxX = 0,
	fovMaxY,
	fovMaxZ};


/** \brief View used to create MPR images */
@interface MPR2DView : NSOpenGLView <Schedulable>
{
	float				blendingAxis[ 3], blendingAngle, blendingAxis2[ 3], blendingAngle2;
	BOOL				negVector;
	long				orientationVector;
	
	vtkTransform		*sliceTransform, *blendingSliceTransform, *perpendicularSliceTransform;

    NSMutableArray      *pixList;
	NSArray				*filesList, *filesListBlending;
    float				*data, *dataFRGB;
	DCMPix              *firstObject;
	
	float				vectors[ 9];
	float				blendingVectors[ 9];
	
    NSMutableArray      *blendingPixList;
    DCMPix              *blendingFirstObject;
    float				*blendingData, blendingFactor;
	ViewerController	*blendingController;
	
	ThickSlabController*	thickSlabCtl;
	
    short               currentTool;
    BOOL                boneVisible, skinVisible;
	
	vtkImageImport		*blendingReader;
	vtkImageActor       *blendingSaggital, *blendingCoronal, *blendingAxial;
    vtkImageMapToColors *blendingAxialColors, *blendingCoronalColors, *blendingSaggitalColors;
	vtkLookupTable      *blendingBwLut;
	float				blendingSliceThickness;
	vtkImageReslice		*slice;
	
	long				FOV, FOVP;
	float				sliceThickness;
	int					extent[6];
	vtkImageReslice		*rotate, *rotatePerpendicular, *blendingRotate;
	
	vtkImageImport		*reader;
    vtkImageActor       *saggital, *coronal, *axial;
    vtkImageMapToColors *axialColors, *coronalColors, *saggitalColors;
    vtkLookupTable      *bwLut;
	
	vtkRenderer         *aRenderer;
    vtkCamera           *aCamera;
	
    vtkActor            *outlineRect;
    vtkPolyDataMapper   *mapOutline;
    vtkOutlineFilter    *outlineData;
	
	vtkImageChangeInformation *changeImageInfo;
	
	vtkLineWidget		*line;
	float				slicePt[3];
	
	IBOutlet PreviewView	*perpendicularView;
	IBOutlet PreviewView	*finalView;
	IBOutlet PreviewView	*finalViewBlending;
	NSMutableArray			*perPixList, *finalPixList, *finalPixListBlending;
	
	BOOL					firstTime, firstTimeBlending;
	
	long					thickSlab;
	long					thickSlabMode;
	float					thickSlabGap;
	
	IBOutlet NSSlider       *sliderThickSlab;
	IBOutlet NSTextField	*textThickSlab;
	IBOutlet NSButton		*activatedThickSlab;
	IBOutlet NSPopUpButton	*thickSlabPopUp;
	
	IBOutlet NSPopUpButton  *OpacityPopup;
	
	BOOL					mouseUpMessagePending;
	
	float					*imResult, *imResultBlending, *fullVolume, *fullVolumeBlending;
	long					thickSlabCount;
	
	int						fovMaxAxis;
}

- (IBAction) setThickSlabActivated: (id) sender;
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(void) adjustWLWW: (float) iwl :(float) iww :(NSString*) mode;
-(void) setCurrentTool:(short) i;
-(id)initWithFrame:(NSRect)frame;
-(short) setPixSource:(NSMutableArray*)pix :(NSArray*)files :(float*) volumeData;
-(void) setBlendingPixSource:(ViewerController*) vc;
-(void) dealloc;
-(void) setBlendingWLWW:(float) wl :(float) ww;
-(void) getWLWW:(float*) wl :(float*) ww;
-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingFactor:(float) f;
-(void) scrollWheelInt:(float) inc :(long) update;
-(IBAction) setThickSlab:(id) sender;
-(IBAction) setThickSlabMode:(id) sender;
-(IBAction) setThickSlabGap:(id) sender;
-(float) thickSlab;
-(void) movieChangeSource:(float*) volumeData;
-(void) movieBlendingChangeSource;
-(void) axView:(id) sender;
-(NSMutableDictionary*) get3DStateDictionary;
-(void) set3DStateDictionary:(NSDictionary*) dict;
-(NSImage*) nsimage:(BOOL) notused;
-(void) setOpacity:(NSArray*) array;
-(void) rotateOriginal :(float) angle;
-(void) rotatePerpendicular :(float) angle;
-(PreviewView*) finalView;
-(void) setOrientationVector:(long) x;
@end
