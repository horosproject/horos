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

#import "DCMPix.h"
#import "Camera.h"

#ifdef __cplusplus
#import "VTKViewOSIRIX.h"
//#define id Id
#include <vtkCommand.h>
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
#include <vtkAnnotatedCubeActor.h>
#include <vtkOrientationMarkerWidget.h>
#include <vtkTextProperty.h>
#ifdef _STEREO_VISION_
// Added SilvanWidmer 10-08-09
// ****************************
#include <vtkCocoaGLView.h>
#include <vtkCocoaRenderWindowInteractor.h>
#include <vtkCocoaRenderWindow.h>
#include <vtkParallelRenderManager.h>
#include <vtkRendererCollection.h>
#include <vtkCallbackCommand.h>
#import "VTKStereoSRView.h>
// ****************************
#endif

//#undef id

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
typedef char* vtkImageFlip;
typedef char* vtkImageResample;
typedef char* vtkMatrix4x4;
typedef char* vtkDecimatePro;
typedef char* vtkSmoothPolyDataFilter;
typedef char* vtkContourFilter;
typedef char* vtkPolyDataNormals;
typedef char* vtkRenderer;
typedef char* vtkOrientationMarkerWidget;

#ifdef _STEREO_VISION_
// ****************************
// Added SilvanWidmer 10-08-09
typedef char* vtkCocoaRenderWindowInteractor;
typedef char* vtkCocoaRenderWindow;
typedef char* vtkParallelRenderManager;
typedef	char* vtkRenderWindow;
typedef char* vtkRendererCollection;
typedef char* vtkCocoaGLView;
typedef char* vtkCallbackCommand;
typedef char* VTKStereoSRView;
// ****************************
#endif

#endif

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

@class Camera;
@class SRController;
@class DICOMExport;

#ifdef _STEREO_VISION_
typedef struct renderSurface
{
	long actor;
	float resolution;
	float transparency;
	float r;
	float g;
	float b;
	float isocontour;
	float decimateVal;
	BOOL useDecimate;
	BOOL useSmooth;
	long smoothVal;
} renderSurface;

#endif

#ifdef __cplusplus
#else
#define VTKView NSView
#endif

/** \brief Surface Rendering View */
@interface SRView : VTKView <NSDraggingSource, NSPasteboardItemDataProvider>
{
	int							projectionMode;
    NSMutableArray				*blendingPixList;
    DCMPix						*blendingLastObject, *blendingFirstObject;
    float						*blendingData, blendingFactor;
	ViewerController			*blendingController;
	vtkImageImport				*blendingReader;
	vtkImageFlip				*flip, *blendingFlip;
	
	vtkTextActor				*textX;
	vtkTextActor				*oText[ 4];
	
	NSCursor					*cursor;
	BOOL						cursorSet;
	
    NSMutableArray				*pixList;
    DCMPix						*firstObject;
    float						*data, *dataFRGB;
    ToolMode					currentTool;
	float						cosines[ 9];
	float						blendingcosines[ 9];

	IBOutlet NSWindow			*export3DWindow;
	IBOutlet NSSlider			*framesSlider;
	IBOutlet NSMatrix			*rotation;
	
	IBOutlet NSWindow			*export3DVRWindow;
	IBOutlet NSMatrix			*VRFrames;
	
	IBOutlet NSColorWell		*backColor;
	
	double						camPosition[ 3];
	double						camFocal[ 3];
	
	long						numberOfFrames;
	float						rotationValue;
	long						rotationOrientation;
	
//	vtkCallbackCommand			*cbStart;
	
	// DICOM export
	IBOutlet NSWindow			*exportDCMWindow;
	IBOutlet NSSlider			*dcmframesSlider;
	IBOutlet NSMatrix			*dcmExportMode, *dcmrotation, *dcmorientation;
	IBOutlet NSBox				*dcmBox;
	IBOutlet NSTextField		*dcmSeriesName;
	
	vtkRenderer					*aRenderer;
    vtkCamera					*aCamera;

    vtkActor					*outlineRect;
    vtkPolyDataMapper			*mapOutline;
    vtkOutlineFilter			*outlineData;
	
	vtkImageImport				*reader;
	
	BOOL						noWaitDialog;
	WaitRendering				*splash;
	DICOMExport					*exportDCM;
	
	vtkImageResample			*isoResample;
	vtkDecimatePro				*isoDeci[ 2];
	vtkSmoothPolyDataFilter		*isoSmoother[ 2];
	vtkContourFilter			*isoExtractor [ 2];
	vtkPolyDataNormals			*isoNormals [ 2];
	vtkPolyDataMapper			*isoMapper [ 2];
	vtkActor					*iso [ 2];

	vtkImageResample			*BisoResample;
	vtkDecimatePro				*BisoDeci[ 2];
	vtkSmoothPolyDataFilter		*BisoSmoother[ 2];
	vtkContourFilter			*BisoExtractor [ 2];
	vtkPolyDataNormals			*BisoNormals [ 2];
	vtkPolyDataMapper			*BisoMapper [ 2];
	vtkActor					*Biso [ 2];
	
	vtkMatrix4x4				*matrice;
	vtkMatrix4x4				*matriceBlending;
	vtkOrientationMarkerWidget	*orientationWidget;
	
	NSDate						*startRenderingTime;
	
	NSMutableArray				*point3DActorArray;
	NSMutableArray				*point3DPositionsArray;
	NSMutableArray				*point3DRadiusArray;
	NSMutableArray				*point3DColorsArray;
	
	NSMutableArray				*point3DDisplayPositionArray;
	NSMutableArray				*point3DTextArray;
	NSMutableArray				*point3DPositionsStringsArray;
	NSMutableArray				*point3DTextSizesArray;
	NSMutableArray				*point3DTextColorsArray;
	
	BOOL						display3DPoints;
	IBOutlet NSPanel			*point3DInfoPanel;
	IBOutlet NSTextField		*point3DPositionTextField;
	IBOutlet NSButton			*point3DDisplayPositionButton;
	IBOutlet NSSlider			*point3DRadiusSlider, *point3DTextSizeSlider;
	IBOutlet NSColorWell		*point3DColorWell, *point3DTextColorWell;
	IBOutlet NSButton			*point3DPropagateToAll, *point3DSetDefault;
	IBOutlet SRController		*controller;
	float						point3DDefaultRadius, point3DDefaultColorRed, point3DDefaultColorGreen, point3DDefaultColorBlue, point3DDefaultColorAlpha;
	
	BOOL						_dragInProgress;
	NSTimer						*_mouseDownTimer;
	NSImage						*destinationImage;
	
	NSPoint						_mouseLocStart;  // mouseDown start point
	BOOL						_resizeFrame;
	ToolMode					_tool;
	
	NSRect						savedViewSizeFrame;

	// 3DConnexion SpaceNavigator
	NSTimer			*snCloseEventTimer;
	BOOL			snStopped;
	UInt16			snConnexionClientID;
	
#ifdef _STEREO_VISION_
	//Added SilvanWidmer 10-08-09
	NSWindow						*LeftFullScreenWindow; 
	NSWindow						*RightFullScreenWindow;   
	BOOL							StereoVisionOn;
	vtkCocoaGLView					*leftView;
	VTKStereoSRView					*rightView;
	NSWindow						*rootWindow;
	NSView							*LeftContentView;
	NSRect							rootSize;
	NSSize							rootBorder;
	
	renderSurface					first;
	renderSurface					second;
	vtkCallbackCommand				*rightResponder;
#endif
	
}

#ifdef _STEREO_VISION_
@property(readwrite) BOOL StereoVisionOn; 
@property(readonly) ToolMode currentTool;
#endif

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(NSDate*) startRenderingTime;
-(void) newStartRenderingTime;
-(void) runRendering;
-(void) startRendering;
-(void) stopRendering;
-(void) setViewSizeToMatrix3DExport;
-(void) setCurrentTool:(ToolMode) i;
-(id) initWithFrame:(NSRect)frame;
-(short) setPixSource:(NSMutableArray*)pix :(float*) volumeData;
-(void) dealloc;
-(void) setBlendingPixSource:(ViewerController*) bC;
- (void) changeActor:(long) actor :(float) resolution :(float) transparency :(float) r :(float) g :(float) b :(float) isocontour :(BOOL) useDecimate :(float) decimateVal :(BOOL) useSmooth :(long) smoothVal;
-(void) deleteActor:(long) actor;
-(void) BchangeActor:(long) actor :(float) resolution :(float) transparency :(float) r :(float) g :(float) b :(float) isocontour :(BOOL) useDecimate :(float) decimateVal :(BOOL) useSmooth :(long) smoothVal;
-(void) BdeleteActor:(long) actor;
-(IBAction) endQuicktimeSettings:(id) sender;
-(IBAction) exportQuicktime :(id) sender;
//-(IBAction) endQuicktimeVRSettings:(id) sender;
- (IBAction) setCurrentdcmExport:(id) sender;
-(IBAction) endDCMExportSettings:(id) sender;
-(void) exportDICOMFile:(id) sender;
-(float) rotation;
-(float) numberOfFrames;
-(void) Azimuth:(float) z;
-(void) Vertical:(float) a;
-(NSImage*) nsimageQuicktime;
-(NSImage*) nsimage:(BOOL) q;
-(IBAction) export3DFileFormat :(id) sender;
-(IBAction) SwitchStereoMode :(id) sender;
- (void) setCamera: (Camera*) cam;
- (Camera*) camera;
-(void) switchOrientationWidget:(id) sender;
- (void) computeOrientationText;
- (void) getOrientation: (float*) o;
-(void) saView:(id) sender;
-(void) axView:(id) sender;
-(void) coView:(id) sender;
-(void) saViewOpposite:(id) sender;
- (IBAction)changeColor:(id)sender;
-(IBAction) switchProjection:(id) sender;
-(void) restoreViewSizeAfterMatrix3DExport;

// 3D Points
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
- (void) convert3Dto2Dpoint:(double*) pt3D :(double*) pt2D;

// 3D Points annotations
- (IBAction) IBSetSelected3DPointAnnotation: (id) sender;
- (void) setAnnotationWithPosition:(int)displayPosition for3DPointAtIndex:(unsigned int) index;
- (void) setAnnotation:(const char*) annotation for3DPointAtIndex:(unsigned int) index;
- (void) displayAnnotationFor3DPointAtIndex:(unsigned int) index;
- (void) hideAnnotationFor3DPointAtIndex:(unsigned int) index;
- (IBAction) IBSetSelected3DPointAnnotationColor: (id) sender;
- (IBAction) IBSetSelected3DPointAnnotationSize: (id) sender;

-(void) setCursorForView: (ToolMode) tool;

//Dragging
- (void) startDrag:(NSTimer*)theTimer;
- (void)deleteMouseDownTimer;
-(void) squareView:(id) sender;

- (void)yaw:(float)degrees;
- (void)panX:(float)x Y:(float)y;

// 3DConnexion SpaceNavigator
- (void)connect2SpaceNavigator;
void SRSpaceNavigatorMessageHandler(io_connect_t connection, natural_t messageType, void *messageArgument);
#ifdef _STEREO_VISION_
//Added SilvanWidmer 27-08-09
- (ToolMode) getTool: (NSEvent*) event;
#endif

@end
