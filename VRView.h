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
#import "VTKView.h"
#import "DCMPix.h"

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
#include "vtkImageFlip.h"
#include "vtkAnnotatedCubeActor.h"
#include "vtkOrientationMarkerWidget.h"
#include "vtkVolumeTextureMapper2D.h"
#include "vtkVolumeTextureMapper3D.h"
//#include "vtkVolumeShearWarpMapper.h"

#include "vtkCellArray.h"
#include "vtkProperty2D.h"

#undef id

class vtkMyCallbackVR;

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
typedef char* vtkFixedPointVolumeRayCastMapper;
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
typedef char* vtkVolumeRayCastCompositeFunction;

typedef char* vtkMyCallbackVR;
#endif

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

@class DICOMExport;
@class Camera;
@class VRController;

@interface VRView : VTKView <Schedulable>
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
	
	vtkFixedPointVolumeRayCastMapper		*blendingVolumeMapper;
	vtkVolumeTextureMapper3D	*blendingTextureMapper;
	
	vtkVolume					*blendingVolume;
	vtkVolumeProperty			*blendingVolumeProperty;
	vtkColorTransferFunction	*blendingColorTransferFunction;
	vtkVolumeRayCastCompositeFunction *blendingCompositeFunction;
	vtkPiecewiseFunction		*blendingOpacityTransferFunction;
	double						blendingtable[256][3];
	
	BOOL						needToFlip, blendingNeedToFlip, firstTime;
//	vtkImageFlip				*flip, *blendingFlip;
	
	IBOutlet NSWindow       *export3DWindow;
	IBOutlet NSSlider		*framesSlider;
	IBOutlet NSMatrix		*quality, *rotation, *orientation;
	IBOutlet NSTextField	*pixelInformation;

	IBOutlet NSWindow			*exportDCMWindow;
	IBOutlet NSSlider			*dcmframesSlider;
	IBOutlet NSMatrix			*dcmExportMode, *dcmquality, *dcmrotation, *dcmorientation;
	IBOutlet NSBox				*dcmBox;
	IBOutlet NSTextField		*dcmSeriesName;

	IBOutlet NSWindow       *export3DVRWindow;
	IBOutlet NSMatrix		*VRFrames;
	IBOutlet NSMatrix		*VRquality;
	IBOutlet NSMatrix		*projection;
	
	IBOutlet NSMatrix		*scissorStateMatrix;
	
	long					numberOfFrames;
	BOOL					bestRenderingMode;
	float					rotationValue, factor;
	long					rotationOrientation, renderingMode;
	
	NSTimer					*mouseModifiers;
	NSArray					*currentOpacityArray;
    NSMutableArray			*pixList;
    DCMPix					*firstObject;
    float					*data;
	
	float					valueFactor, blendingValueFactor;
	float					OFFSET16, blendingOFFSET16;
	
	unsigned char			*dataFRGB;
	char					*data8;
	vImage_Buffer			srcf, dst8;

    short					currentTool;
	float					wl, ww;
	float					LOD;
	float					cosines[ 9];
	float					blendingcosines[ 9];
	double					table[256][3];
	double					alpha[ 256];

	NSCursor				*cursor;
	
    vtkRenderer				*aRenderer;
    vtkCamera				*aCamera;

    vtkActor				*outlineRect;
    vtkPolyDataMapper		*mapOutline;
    vtkOutlineFilter		*outlineData;
	
	vtkMyCallbackVR				*cropcallback;
	vtkPlaneWidget				*planeWidget;
	vtkOrientationMarkerWidget	*orientationWidget;
	vtkBoxWidget				*croppingBox;
	double						initialCroppingBoxBounds[6];
	// MAPPERS
	
	vtkFixedPointVolumeRayCastMapper			*volumeMapper;
	vtkVolumeTextureMapper3D		*textureMapper;
	
	vtkVolume					*volume;
	vtkVolumeProperty			*volumeProperty;
	vtkColorTransferFunction	*colorTransferFunction;
	vtkTextActor				*textWLWW, *textX;
	BOOL						isViewportResizable;
	vtkTextActor				*oText[ 4];
	char						WLWWString[ 200];
	vtkImageImport				*reader;
	vtkVolumeRayCastCompositeFunction  *compositeFunction;
	vtkPiecewiseFunction		*opacityTransferFunction;
	
	vtkColorTransferFunction	*red, *green, *blue;
	BOOL						noWaitDialog, isRGB, isBlendingRGB, ROIUPDATE;
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
	vtkCallbackCommand			*cbStart;
	
	BOOL						clamping;
	
	DICOMExport					*exportDCM;
	
	NSMutableArray				*point3DActorArray;
	NSMutableArray				*point3DPositionsArray;
	NSMutableArray				*point3DRadiusArray;
	NSMutableArray				*point3DColorsArray;
	BOOL						display3DPoints;
	IBOutlet NSPanel			*point3DInfoPanel;
	IBOutlet NSSlider			*point3DRadiusSlider;
	IBOutlet NSColorWell		*point3DColorWell;
	IBOutlet NSButton			*point3DPropagateToAll, *point3DSetDefault;
	IBOutlet VRController		*controller;
	float						point3DDefaultRadius, point3DDefaultColorRed, point3DDefaultColorGreen, point3DDefaultColorBlue, point3DDefaultColorAlpha;
	
	BOOL						_dragInProgress;
	NSTimer						*_mouseDownTimer;
	NSImage						*destinationImage;
	
	NSPoint						_mouseLocStart;  // mouseDown start point
	BOOL						_resizeFrame;
	short						_tool;
	
	float						_startWW, _startWL, _startMin, _startMax;
}

+ (BOOL) getCroppingBox:(double*) a :(vtkVolume *) volume :(vtkBoxWidget*) croppingBox;
+ (void) setCroppingBox:(double*) a :(vtkVolume *) volume;

- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait;
- (void) endRenderImageWithBestQuality;

- (void)changeColorWith:(NSColor*) color;
- (void) exportDICOMFile:(id) sender;
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(void) set3DStateDictionary:(NSDictionary*) dict;
-(NSMutableDictionary*) get3DStateDictionary;
- (void) setBlendingEngine: (long) engineID;
- (void) getShadingValues:(float*) ambient :(float*) diffuse :(float*) specular :(float*) specularpower;
- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower;
-(void) movieChangeSource:(float*) volumeData;
-(void) movieChangeSource:(float*) volumeData showWait :(BOOL) showWait;
-(void) movieBlendingChangeSource:(long) index;
-(void) setBlendingWLWW:(float) iwl :(float) iww;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingFactor:(float) a;
-(NSDate*) startRenderingTime;
-(void) newStartRenderingTime;
-(void) deleteStartRenderingTime;
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
-(void) Vertical:(float) z;
-(NSImage*) nsimageQuicktime;
-(NSImage*) nsimage:(BOOL) q;
-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(IBAction) switchShading:(id) sender;
-(long) shading;
- (void) setEngine: (long) engineID;
-(IBAction) switchProjection:(id) sender;
- (void) setProjectionMode: (int) mode;
- (IBAction) resetImage:(id) sender;
-(void) saView:(id) sender;
- (IBAction)setRenderMode:(id)sender;
- (void) setBlendingMode: (long) modeID;
-(NSImage*) nsimageQuicktime:(BOOL) renderingMode;
- (void) setCamera: (Camera*) cam;
- (Camera*) camera;
- (IBAction) scissorStateButtons:(id) sender;
- (void) updateScissorStateButtons;
-(void) switchOrientationWidget:(id) sender;
- (void) computeOrientationText;
- (void) getOrientation: (float*) o;
-(void) bestRendering:(id) sender;
- (void) setMode: (long) modeID;
- (long) mode;
-(void)resizeWindowToScale:(float)resizeScale;
- (IBAction)resizeWindow:(id)sender;
- (float) getResolution;

- (BOOL) isViewportResizable;
- (void) setViewportResizable: (BOOL) boo;

// 3D Points
- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val;
- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: (float) maxOpacity minValue: (float) minValue;

- (void) add3DPoint: (double) x : (double) y : (double) z : (float) radius : (float) r : (float) g : (float) b;
- (void) add3DPoint: (double) x : (double) y : (double) z;
- (void) add3DPointActor: (vtkActor*) actor;
- (void) addRandomPoints: (int) n : (int) r;
- (void) throw3DPointOnSurface: (double) x : (double) y;
- (void) setDisplay3DPoints: (BOOL) on;
- (void) toggleDisplay3DPoints;
- (BOOL) isAny3DPointSelected;
- (unsigned int) selected3DPointIndex;
- (void) unselectAllActors;
- (void) remove3DPointAtIndex: (unsigned int) index;
- (void) removeSelected3DPoint;
- (IBAction) IBSetSelected3DPointColor: (id) sender;
- (IBAction) IBSetSelected3DPointRadius: (id) sender;
- (IBAction) IBPropagate3DPointsSettings: (id) sender;
- (void) setSelected3DPointColor: (NSColor*) color;
- (void) setAll3DPointsColor: (NSColor*) color;
- (void) set3DPointAtIndex:(unsigned int) index Color: (NSColor*) color;
- (void) setSelected3DPointRadius: (float) radius;
- (void) setAll3DPointsRadius: (float) radius;
- (void) set3DPointAtIndex:(unsigned int) index Radius: (float) radius;
- (IBAction) save3DPointsDefaultProperties: (id) sender;
- (void) load3DPointsDefaultProperties;
- (void) convert3Dto2Dpoint:(float*) pt3D :(float*) pt2D;
- (IBAction) setCurrentdcmExport:(id) sender;
- (IBAction) switchToSeriesRadio:(id) sender;
- (float) offset;
- (float) valueFactor;
- (void) setViewportResizable: (BOOL) boo;

- (void) setRotate: (BOOL) r;
- (float) factor;

// export
- (void) sendMail:(id) sender;
- (void) exportJPEG:(id) sender;
- (void) export2iPhoto:(id) sender;
- (void) exportTIFF:(id) sender;

// cursors
-(void) setCursorForView: (long) tool;

//Dragging
- (void) startDrag:(NSTimer*)theTimer;
- (void)deleteMouseDownTimer;

@end
