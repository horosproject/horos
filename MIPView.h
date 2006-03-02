/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <AppKit/AppKit.h>

#import "DCMPix.h"
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
#include "vtkVolumeTextureMapper2D.h"
#include "vtkCellArray.h"
#include "vtkProperty2D.h"

#undef id

class vtkMyCallback;

#else
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
typedef char* vtkFixedPointVolumeRayCastMapper;

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

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

@interface MIPView : VTKView <Schedulable>
{
	vtkTextActor				*textWLWW;
	char						WLWWString[ 200];
	
	NSMutableArray				*blendingPixList;
    DCMPix						*blendingFirstObject;
    float						*blendingData, blendingFactor;
	ViewerController			*blendingController;
	char						*blendingData8;
	vImage_Buffer				blendingSrcf, blendingDst8;
	long						blendingWl, blendingWw;
	vtkImageImport				*blendingReader;
	vtkVolumeRayCastMapper		*blendingVolumeMapper;
	vtkVolume					*blendingVolume;
	vtkVolumeProperty			*blendingVolumeProperty;
	vtkColorTransferFunction	*blendingColorTransferFunction;
	vtkVolumeRayCastMIPFunction *blendingCompositeFunction;
	vtkPiecewiseFunction		*blendingOpacityTransferFunction;
	
	NSArray					*currentOpacityArray;
    NSMutableArray			*pixList;
    DCMPix					*firstObject;
    float					*data;//, *dataFRGB;
	BOOL					dataSwitch;
//	char					*data8;
//	vImage_Buffer			srcf, dst8;
    short					currentTool;
    BOOL					boneVisible, skinVisible;
	long					wl, ww;
	float					LOD;
	float					cosines[ 9];
	float					blendingcosines[ 9];
	double					table[256][3];
	
    vtkRenderer				*aRenderer;
    vtkCamera				*aCamera;

    vtkActor				*outlineRect;
    vtkPolyDataMapper		*mapOutline;
    vtkOutlineFilter		*outlineData;
	
	vtkMyCallback				*cropcallback;
	vtkPlaneWidget				*planeWidget;
	vtkBoxWidget				*croppingBox;
	
	vtkFixedPointVolumeRayCastMapper		*volumeMapper;
	vtkVolumeTextureMapper2D	*textureMapper;
	
	vtkVolume					*volume;
	vtkVolumeProperty			*volumeProperty;
	vtkColorTransferFunction	*colorTransferFunction;
	vtkImageImport				*reader;
	vtkVolumeRayCastMIPFunction  *compositeFunction;
	vtkPiecewiseFunction		*opacityTransferFunction;
	vtkColorTransferFunction	*red, *green, *blue;
	
	BOOL						noWaitDialog, ROIUPDATE;
	WaitRendering				*splash;
	
	IBOutlet NSWindow			*export3DWindow;
	IBOutlet NSSlider			*framesSlider;
	IBOutlet NSMatrix			*quality, *rotation;

	IBOutlet NSWindow			*exportDCMWindow;
	IBOutlet NSSlider			*dcmframesSlider;
	IBOutlet NSMatrix			*dcmExportMode, *dcmquality, *dcmrotation;
	
	IBOutlet NSWindow			*export3DVRWindow;
	IBOutlet NSMatrix			*VRFrames;
	IBOutlet NSMatrix			*VRquality;
	double						camPosition[ 3], camFocal[ 3];
	
	long						numberOfFrames;
	BOOL						bestRenderingMode;
	float						rotationValue, factor;
	
	NSDate						*startRenderingTime;
	
	vtkPolyData					*ROI3DData;
	vtkPolyDataMapper2D			*ROI3D;
	vtkActor2D					*ROI3DActor;
	
	DICOMExport					*exportDCM;
}

-(void) setOpacity:(NSArray*) array;
-(void) set3DStateDictionary:(NSDictionary*) dict;
-(NSMutableDictionary*) get3DStateDictionary;
-(void) setBlendingWLWW:(long) iwl :(long) iww;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) movieChangeSource:(float*) volumeData;
-(void) setBlendingFactor:(float) a;
-(NSDate*) startRenderingTime;
-(void) newStartRenderingTime;
-(void) startRendering;
-(void) stopRendering;
-(void) runRendering;
-(void) setLOD:(float)f;
-(void) setCurrentTool:(short) i;
-(id)initWithFrame:(NSRect)frame;
-(short)setPixSource:(NSMutableArray*)pix :(float*) volumeData;
-(void)dealloc;
- (void) setWLWW:(long) wl :(long) ww;
- (void) getWLWW:(long*) wl :(long*) ww;
-(void) setBlendingPixSource:(ViewerController*) bC;
-(IBAction) endQuicktimeVRSettings:(id) sender;
-(IBAction) endDCMExportSettings:(id) sender;
-(IBAction) exportDICOM:(id) sender;
-(IBAction) endQuicktimeSettings:(id) sender;
-(IBAction) exportQuicktime3D :(id) sender;
-(float) rotation;
-(float) numberOfFrames;
-(void) Azimuth:(float) z;
-(NSImage*) nsimageQuicktime;
-(NSImage*) nsimage:(BOOL) q;
-(IBAction) switchProjection:(id) sender;
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) movieBlendingChangeSource:(long) index;
@end
