/*=========================================================================
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
#import "VTKView.h"
#import "DCMPix.h"

#ifdef __cplusplus

#include "vli3.h"

#define id Id

#include "vtkVolumeProMapper.h"
#include "vtkVolumeProVP1000Mapper.h"
#include "vtkOpenGLVolumeProVP1000Mapper.h"

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
//#include "vtkOpenGLVolumeRayCastMapper.h"
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
#include "vtkTextActor.h"
#include "vtkTextProperty.h"
#include "vtkImageFlip.h"
#include "vtkAnnotatedCubeActor.h"
#include "vtkOrientationMarkerWidget.h"
#include "vtkVolumeTextureMapper2D.h"
#include "vtkCellArray.h"
#include "vtkProperty2D.h"
#undef id
class vtkMyCallbackVP;
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
typedef char* vtkMyCallbackVP;
typedef char* vtkOpenGLVolumeProVP1000Mapper;
typedef char* vtkVolumeRayCastCompositeFunction;
#endif


#import "Accelerate.h"
#import "ViewerController.h"
#import "WaitRendering.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

@class DICOMExport;
@class Camera;

/** \brief VRView for VRPro  */

@interface VRPROView : VTKView <Schedulable>
{
	NSTimer						*autoRotate;
	BOOL						rotate;

	int							projectionMode;
    NSMutableArray				*blendingPixList;
    DCMPix						*blendingFirstObject;
    float						*blendingData, blendingFactor;
	ViewerController			*blendingController;
	char						*blendingData8;
	vImage_Buffer				blendingSrcf, blendingDst8;
	float						blendingWl, blendingWw;
	vtkImageImport				*blendingReader;
	
	vtkVolumeRayCastMapper		*blendingVolumeMapper;
	vtkOpenGLVolumeProVP1000Mapper			*blendingTextureMapper;
//	vtkVolumeShearWarpMapper	*blendingShearWarpMapper;
	
	vtkVolume					*blendingVolume;
	vtkVolumeProperty			*blendingVolumeProperty;
	vtkColorTransferFunction	*blendingColorTransferFunction;
	vtkVolumeRayCastCompositeFunction *blendingCompositeFunction;
	vtkPiecewiseFunction		*blendingOpacityTransferFunction;
//	vtkCallbackCommand			*cbStart;
	
//	vtkImageFlip				*flip, *blendingFlip;
	BOOL					needToFlip;
	
	IBOutlet NSWindow       *export3DWindow;
	IBOutlet NSSlider		*framesSlider;
	IBOutlet NSMatrix		*rotation, *orientation;

	IBOutlet NSWindow			*exportDCMWindow;
	IBOutlet NSSlider			*dcmframesSlider;
	IBOutlet NSMatrix			*dcmExportMode, *dcmrotation, *dcmorientation;
	IBOutlet NSBox				*dcmBox;
	IBOutlet NSTextField		*dcmSeriesName;
	
	IBOutlet NSWindow       *export3DVRWindow;
	IBOutlet NSMatrix		*VRFrames;
	IBOutlet NSMatrix		*projection;
	
	IBOutlet NSMatrix		*scissorStateMatrix;
	
	long					numberOfFrames;
	BOOL					bestRenderingMode;
	float					rotationValue, factor;
	long					rotationOrientation;
	
    NSMutableArray			*pixList;
    DCMPix					*firstObject;
    float					*data;
	float					*dataFRGB, *undodata;
	BOOL					dataSwitch, ROIUPDATE;
	char					*data8;
	vImage_Buffer			srcf, dst8;
    short					currentTool;
	float					wl, ww;
	float					LOD;
	float					cosines[ 9];
	float					blendingcosines[ 9];
	double					table[256][3];
	double					tableOpacity[256];
	
    vtkRenderer				*aRenderer;
    vtkCamera				*aCamera;

//    vtkActor				*outlineRect;
    vtkPolyDataMapper		*mapOutline;
    vtkOutlineFilter		*outlineData;
	
	vtkMyCallbackVP			*cropcallback;
	vtkPlaneWidget			*planeWidget;
	vtkOrientationMarkerWidget	*orientationWidget;
	vtkBoxWidget			*croppingBox;
	
	// MAPPERS
	
	vtkVolumeRayCastMapper			*volumeMapper;
	vtkOpenGLVolumeProVP1000Mapper	*textureMapper;
//	vtkVolumeShearWarpMapper		*shearWarpMapper;

	vtkVolume					*volume;
	vtkVolumeProperty			*volumeProperty;
	vtkColorTransferFunction	*colorTransferFunction;
	vtkTextActor				*textWLWW, *textX;
	vtkTextActor				*oText[ 4];
	char						WLWWString[ 200];
	vtkImageImport				*reader;
	vtkVolumeRayCastCompositeFunction  *compositeFunction;
	vtkPiecewiseFunction		*opacityTransferFunction;
	
	BOOL						noWaitDialog, isRGB;
	WaitRendering				*splash;
	
	double						camPosition[ 3], camFocal[ 3];
	
	NSDate						*startRenderingTime;
	
	vtkPolyData					*ROI3DData;
	vtkPolyDataMapper2D			*ROI3D;
	vtkActor2D					*ROI3DActor;
	
	vtkPolyData					*Line2DData;
	vtkPolyDataMapper2D			*Line2D;
	vtkActor2D					*Line2DActor;
	vtkTextActor				*Line2DText;
	
	DICOMExport					*exportDCM;
	
	NSCursor					*cursor;
	BOOL						cursorSet;
	
	NSRect						savedViewSizeFrame;
}
-(void) set3DStateDictionary:(NSDictionary*) dict;
-(void) movieChangeSource:(float*) volumeData;
-(void) movieBlendingChangeSource:(long) index;
-(void) setBlendingWLWW:(float) iwl :(float) iww;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(NSMutableDictionary*) get3DStateDictionary;
-(void) setBlendingFactor:(float) a;
-(void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower;
-(void) setBlendingEngine: (long) engineID;
-(void) getShadingValues:(float*) ambient :(float*) diffuse :(float*) specular :(float*) specularpower;
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(void) updateVolumePRO;
-(NSDate*) startRenderingTime;
-(void) newStartRenderingTime;
-(void) setOpacity:(NSArray*) array;
-(void) runRendering;
-(void) startRendering;
-(void) stopRendering;
-(void) setLOD:(float)f;
-(void) setCurrentTool:(short) i;
-(id)initWithFrame:(NSRect)frame;
-(short)setPixSource:(NSMutableArray*)pix :(float*) volumeData;
-(void)dealloc;
-(void) setWLWW:(float) wl :(float) ww;
-(void) getWLWW:(float*) wl :(float*) ww;
-(void) setBlendingPixSource:(ViewerController*) bC;
-(IBAction) endQuicktimeSettings:(id) sender;
-(IBAction) endDCMExportSettings:(id) sender;
-(IBAction) endQuicktimeVRSettings:(id) sender;
-(IBAction) exportQuicktime :(id) sender;
-(float) rotation;
-(float) numberOfFrames;
-(void) Azimuth:(float) z;
-(void) Vertical:(float) a;
-(NSImage*) nsimageQuicktime;
-(NSImage*) nsimage:(BOOL) q;
-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(IBAction) switchShading:(id) sender;
-(long) shading;
- (void) setEngine: (long) engineID;
- (IBAction) switchProjection:(id) sender;
- (IBAction) scissorStateButtons:(id) sender;
- (void) updateScissorStateButtons;
- (void) setMode: (long) modeID;
-(void) switchOrientationWidget:(id) sender;
- (void) computeOrientationText;
- (void) getOrientation: (float*) o;
- (void) setLowResolutionCamera: (Camera*) cam;
- (IBAction) switchToSeriesRadio:(id) sender;
- (IBAction) setCurrentdcmExport:(id) sender;
+ (BOOL) getCroppingBox:(double*) a :(vtkVolume *) volume :(vtkBoxWidget*) croppingBox;
+ (void) setCroppingBox:(double*) a :(vtkVolume*) volume;
-(void) setCursorForView: (long) tool;
- (long) offset;
- (float) valueFactor;
@end
