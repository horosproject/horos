/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <AppKit/AppKit.h>
#import "DCMPix.h"
#import "ViewerController.h"
#import "PreviewView.h"
#import "VTKView.h"

#ifdef __cplusplus
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
#include "vtkImageMapper.h"
#include "vtkActor2D.h"
#include "vtkProperty2D.h"
#include "vtkPicker.h"
#undef id

#else
@class VTKView;
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
typedef char* vtkPlaneWidget;
typedef char* vtkBoxWidget;
#endif

@interface MPRView : VTKView
{
	IBOutlet PreviewView	*selectedPlane;
	long				selectedPlaneID;
	BOOL				doRotate;
    NSMutableArray      *pixList;
	NSArray				*fileList;
    float				*data, *dataFRGB;
	DCMPix              *firstObject;
	
	float				vectors[ 9];
	float				blendingVectors[ 9];
	
    NSMutableArray      *blendingPixList;
    DCMPix              *blendingFirstObject;
    float				*blendingData, blendingFactor;
	ViewerController	*blendingController;
	
    short               currentTool;
    BOOL                boneVisible, skinVisible;
	
	vtkImageActor       *blendingSaggital, *blendingCoronal, *blendingAxial;
    vtkImageMapToColors *blendingAxialColors, *blendingCoronalColors, *blendingSaggitalColors, *blendingThickSlabColors;
	vtkLookupTable      *blendingBwLut;
	float				blendingSliceThickness;
	vtkImageReslice		*slice;
			
	float				sliceThickness, invThick;
	int					extent[6];
	vtkImageReslice		*rotate;
	
	vtkImageImport		*reader;
    vtkImageActor       *saggital, *coronal, *axial, *imageActor2D, *thickSlabActor;
    vtkImageMapToColors *axialColors, *coronalColors, *saggitalColors, *image2DColors, *thickSlabColors;
    vtkLookupTable      *bwLut;

	IBOutlet NSSlider       *sliderThickSlab;
	IBOutlet NSTextField	*textThickSlab;
	
	vtkRenderer         *aRenderer;
    vtkCamera           *aCamera;
	
    vtkActor            *outlineRect;
    vtkPolyDataMapper   *mapOutline;
    vtkOutlineFilter    *outlineData;
	
	IBOutlet NSWindow   *export3DWindow;
	IBOutlet NSSlider   *framesSlider;
	IBOutlet NSMatrix   *rotation;
	
	IBOutlet NSWindow   *export3DVRWindow;
	IBOutlet NSMatrix   *VRFrames;
	double				camPosition[ 3], camFocal[ 3];

	long				numberOfFrames;
	float				rotationValue;
	
	NSMutableArray*		perPixList;
	BOOL				firstTime;
	
	NSTimer				*rotateTimer;
	BOOL				rotateActivated, coronalPlane;
	float				rotateSpeed;
	
	float				rotationpane[ 3];
	NSPoint				originpane[ 3];
	float				scalepane[ 3];
	
	long				thickSlab;
	long				thickSlabMode;
}
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(short) setPixSource:(NSMutableArray*)pix :(NSArray*)f :(float*) volumeData;
-(void) movieChangeSource:(float*) volumeData;
- (IBAction) switchRotate:(id) sender;
- (IBAction) rotateSpeed:(id) sender;
- (void)stopRotateTimer;
-(void) setSelectedPlaneID:(long) i;
-(void) setCurrentTool:(short) i;
-(id)initWithFrame:(NSRect)frame;
-(void) setBlendingPixSource:(ViewerController*) vc;
-(void) dealloc;
-(void) movePlanes:(float) x :(float) y :(float) z;
-(void) setWLWW:(float) wl :(float) ww;
-(void) setBlendingWLWW:(float) wl :(float) ww;
-(void) getWLWW:(float*) wl :(float*) ww;
-(void) switchActor:(id) sender;
-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingFactor:(float) f;
-(IBAction) endQuicktimeSettings:(id) sender;
-(IBAction) endQuicktimeVRSettings:(id) sender;
-(IBAction) exportQuicktime :(id) sender;
-(float) rotation;
-(float) numberOfFrames;
-(void) Azimuth:(float) z;
-(NSImage*) nsimageQuicktime;
-(NSImage*) nsimage:(BOOL) q;

-(IBAction) setThickSlab:(id) sender;
-(IBAction) setThickSlabMode:(id) sender;
@end
