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
#import "DCMView.h"

#ifdef __cplusplus
#import "VTKViewOSIRIX.h"

//#define id Id
#include <vtkCommand.h>
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
#include <vtkPiecewiseFunction.h>
#include <vtkPiecewiseFunction.h>
#include <vtkColorTransferFunction.h>
#include <vtkVolumeProperty.h>
#include <vtkVolumeRayCastCompositeFunction.h>
#include <vtkVolumeRayCastMapper.h>
#include <vtkVolumeRayCastMIPFunction.h>
#include <vtkFixedPointVolumeRayCastMapper.h>
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
#include <vtkTextActor.h>
#include <vtkTextProperty.h>
#include <vtkImageFlip.h>
#include <vtkAnnotatedCubeActor.h>
#include <vtkOrientationMarkerWidget.h>
#include <vtkVolumeTextureMapper2D.h>
#include <vtkSmartVolumeMapper.h>
#include <vtkGPUVolumeRayCastMapper.h>
#include "vtkHorosFixedPointVolumeRayCastMapper.h"

#include <vtkCellArray.h>
#include <vtkProperty2D.h>
#include <vtkRegularPolygonSource.h>

#ifdef _STEREO_VISION_
// Added SilvanWidmer 10-08-09
// ****************************
#import	<VTK/vtkCocoaGLView.h>
#include <vtkCocoaRenderWindowInteractor.h>
#include <vtkCocoaRenderWindow.h>
#include <vtkParallelRenderManager.h>
#include <vtkRendererCollection.h>
#include <vtkCallbackCommand.h>
#import	"VTKStereoVRView.h>
// ****************************
#endif

//#undef id

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
typedef char* vtkVolumeMapper;
typedef char* vtkVolumeRayCastMapper;
typedef char* vtkFixedPointVolumeRayCastMapper;
typedef char* vtkHorosFixedPointVolumeRayCastMapper;
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
typedef char* vtkBoxWidget;
typedef char* vtkVolumeRayCastCompositeFunction;

typedef char* vtkRenderer;
typedef char* vtkVolumeTextureMapper3D;
typedef char* vtkSmartVolumeMapper;
typedef char* vtkGPUVolumeRayCastMapper;
typedef char* vtkOrientationMarkerWidget;
typedef char* vtkRegularPolygonSource;

typedef char* vtkMyCallbackVR;

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
typedef char* VTKStereoVRView;
// ****************************
#endif
#endif

#include <Accelerate/Accelerate.h>
#import "ViewerController.h"
#import "WaitRendering.h"

@class DICOMExport;
@class Camera;
@class VRController;
@class OSIVoxel;

#import "CLUTOpacityView.h"

/** \brief  Volume Rendering View
*
*   View for volume rendering and MIP
*/
#ifdef __cplusplus
#else
#define VTKView NSView
#endif

@interface VRView : VTKView <NSDraggingSource, NSPasteboardItemDataProvider>
{
	NSTimer						*autoRotate, *startAutoRotate;
	BOOL						isRotating, flyto;
	
    int                         engine;
    
	float						flyToDestination[ 3];

	int							projectionMode;
    NSMutableArray				*blendingPixList;
    DCMPix						*blendingFirstObject;
    float						*blendingData, blendingFactor;
	ViewerController			*blendingController;
	char						*blendingData8;
	vImage_Buffer				blendingSrcf, blendingDst8;
	float						blendingWl, blendingWw, measureLength;
	vtkImageImport				*blendingReader;
	
	vtkHorosFixedPointVolumeRayCastMapper *blendingVolumeMapper;
	vtkGPUVolumeRayCastMapper	*blendingTextureMapper;
	
	vtkVolume					*blendingVolume;
	vtkVolumeProperty			*blendingVolumeProperty;
	vtkColorTransferFunction	*blendingColorTransferFunction;
	vtkVolumeRayCastCompositeFunction *blendingCompositeFunction;
	vtkPiecewiseFunction		*blendingOpacityTransferFunction;
	double						blendingtable[257][3];
	
	BOOL						needToFlip, blendingNeedToFlip, firstTime, alertDisplayed;
	
	IBOutlet NSWindow			*export3DWindow;
	IBOutlet NSSlider			*framesSlider;
	IBOutlet NSMatrix			*quality, *rotation, *orientation;
	IBOutlet NSTextField		*pixelInformation;

	IBOutlet NSWindow			*exportDCMWindow;
	IBOutlet NSSlider			*dcmframesSlider;
	IBOutlet NSMatrix			*dcmExportMode, *dcmquality, *dcmrotation, *dcmorientation;
	IBOutlet NSBox				*dcmBox;
	IBOutlet NSMatrix			*dcmExportDepth;
	IBOutlet NSTextField		*dcmSeriesName;
	NSString					*dcmSeriesString;
	
	IBOutlet NSWindow       *export3DVRWindow;
	IBOutlet NSMatrix		*VRFrames;
	IBOutlet NSMatrix		*VRquality;
	
	IBOutlet NSMatrix		*scissorStateMatrix;
    
	IBOutlet NSColorWell	*viewBackgroundColor;
	
	IBOutlet NSObjectController	*shadingController;
	
	long					numberOfFrames;
	BOOL					bestRenderingMode;
	float					rotationValue, factor;
	long					rotationOrientation, renderingMode;
	
	NSArray					*currentOpacityArray;
    NSMutableArray			*pixList;
    DCMPix					*firstObject;
    float					*data;
	
	float					valueFactor, blendingValueFactor;
	float					OFFSET16, blendingOFFSET16;
	
	unsigned char			*dataFRGB;
	char					*data8;
	vImage_Buffer			srcf, dst8;

    ToolMode				currentTool;
	float					wl, ww;
	float					LOD, lowResLODFactor, lodDisplayed;
	float					cosines[ 9];
	float					blendingcosines[ 9];
	double					table[257][3];
	double					alpha[ 257];

	NSCursor				*cursor;
	BOOL					cursorSet;
	
    vtkRenderer				*aRenderer;
    vtkCamera				*aCamera;

    vtkActor				*outlineRect;
    vtkPolyDataMapper		*mapOutline;
    vtkOutlineFilter		*outlineData;
	
	vtkMyCallbackVR				*cropcallback;
	vtkOrientationMarkerWidget	*orientationWidget;
	vtkBoxWidget				*croppingBox;
//	double						initialCroppingBoxBounds[6];
//	BOOL						dontUseAutoCropping;
	
	
	// MAPPERS
	
	vtkHorosFixedPointVolumeRayCastMapper *volumeMapper;
	vtkGPUVolumeRayCastMapper		*textureMapper;
	
	vtkVolume					*volume;
	vtkVolumeProperty			*volumeProperty;
	vtkColorTransferFunction	*colorTransferFunction;
	vtkTextActor				*textWLWW, *textX;
	BOOL						isViewportResizable;
	vtkTextActor				*oText[ 5];
	char						WLWWString[ 200];
	vtkImageImport				*reader;
	vtkVolumeRayCastCompositeFunction  *compositeFunction;
	vtkPiecewiseFunction		*opacityTransferFunction;
	
	vtkColorTransferFunction	*red, *green, *blue;
	BOOL						noWaitDialog, isRGB, isBlendingRGB, ROIUPDATE;
	WaitRendering				*splash;
	
	double						camPosition[ 3], camFocal[ 3];
	
	NSMutableArray				*ROIPoints;
	
	vtkPolyData					*ROI3DData;
	vtkPolyDataMapper2D			*ROI3D;
	vtkActor2D					*ROI3DActor;
	
	vtkPolyData					*Line2DData;
	vtkPolyDataMapper2D			*Line2D;
	vtkActor2D					*Line2DActor;
	vtkTextActor				*Line2DText;
	
    vtkRegularPolygonSource		*Oval2DData;
	vtkPolyDataMapper2D			*Oval2D;
	vtkActor2D					*Oval2DActor;
	vtkTextActor				*Oval2DText;
    float                       Oval2DCos[ 9], Oval2DPosition[ 3];
    DCMPix                      *Oval2DPix;
    
    NSPoint                     Oval2DCenter, WorldOval2DCenter;
    double                      Oval2DRadius;
    
    double                      Oval2DSampleDistance;
    int                         Oval2DPixZBufferOrigin[2];
    
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
	NSTimer						*_mouseDownTimer, *_rightMouseDownTimer;
	NSImage						*destinationImage;
	
	NSPoint						_mouseLocStart, _previousLoc;  // mouseDown start point
	BOOL						_resizeFrame;
	ToolMode					_tool;
	
	float						_startWW, _startWL, _startMin, _startMax;
	
	NSRect						savedViewSizeFrame;
	
	float						firstPixel, secondPixel;
	
	NSLock						*deleteRegion;
	
	IBOutlet CLUTOpacityView	*clutOpacityView;
	BOOL						advancedCLUT;
	NSData						*appliedCurves;
	BOOL						appliedResolution;
	BOOL						gDataValuesChanged;

	float						verticalAngleForVR;
	float						rotateDirectionForVR;
	
	BOOL						_contextualMenuActive;
	
	//Context for rendering to iChat
	BOOL						_hasChanged;
	float						iChatWidth, iChatHeight;
	BOOL						iChatFrameIsSet;
	
	// 3DConnexion SpaceNavigator
	NSTimer			*snCloseEventTimer;
	BOOL			snStopped;
	UInt16			snConnexionClientID;
	
	BOOL			clipRangeActivated;
	double			clippingRangeThickness;
	
	BOOL			bestRenderingWasGenerated;
	float superSampling;
	BOOL dontResetImage, keep3DRotateCentered;
	int fullDepthMode, fullDepthEngineCopy;
	
#ifdef _STEREO_VISION_
	//Added SilvanWidmer 10-08-09
	NSWindow						*LeftFullScreenWindow; 
	NSWindow						*RightFullScreenWindow;   
	BOOL							StereoVisionOn;
	vtkCocoaGLView					*leftView;
	VTKStereoVRView					*rightView;
	NSWindow						*rootWindow;
	NSView							*LeftContentView;
	NSRect							rootSize;
	NSSize							rootBorder;
	vtkCallbackCommand				*rightResponder;
#endif
}

#ifdef _STEREO_VISION_
@property(readwrite) BOOL StereoVisionOn; 
//@property(readonly) ToolMode currentTool;
#endif

@property (nonatomic) BOOL clipRangeActivated, keep3DRotateCentered, dontResetImage, bestRenderingMode;
@property (nonatomic) int projectionMode;
@property (nonatomic) double clippingRangeThickness;
@property (nonatomic) float lowResLODFactor, lodDisplayed;
@property long renderingMode;
@property (nonatomic) int engine;
@property (readonly) NSArray* currentOpacityArray;
@property (retain) DICOMExport *exportDCM;
@property (retain) NSString *dcmSeriesString;

+ (void) testGraphicBoard;
//+ (BOOL) getCroppingBox:(double*) a :(vtkVolume *) volume :(vtkBoxWidget*) croppingBox;
//+ (void) setCroppingBox:(double*) a :(vtkVolume *) volume;
//- (void) setBlendingCroppingBox:(double*) a;
//- (void) setCroppingBox:(double*) a;
//- (BOOL) croppingBox:(double*) a;
- (void) showCropCube:(id) sender;
- (void) restoreFullDepthCapture;
- (void) prepareFullDepthCapture;
- (float*) imageInFullDepthWidth: (long*) w height:(long*) h isRGB:(BOOL*) isRGB;
- (float*) imageInFullDepthWidth: (long*) w height:(long*) h isRGB:(BOOL*) rgb blendingView:(BOOL) blendingView;
- (NSDictionary*) exportDCMCurrentImage;
- (NSDictionary*) exportDCMCurrentImageIn16bit: (BOOL) fullDepth;
- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait;
- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait display: (BOOL) display;
- (void) endRenderImageWithBestQuality;
- (void) resetAutorotate:(id) sender;
- (void) setEngine: (long) engineID showWait:(BOOL) showWait;
- (IBAction)changeColorWith:(NSColor*) color;
- (IBAction)changeColor:(id)sender;
- (NSColor*) backgroundColor;
- (void) exportDICOM;
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits offset:(int*) offset isSigned:(BOOL*) isSigned;
-(void) set3DStateDictionary:(NSDictionary*) dict;
-(NSMutableDictionary*) get3DStateDictionary;
- (void) setBlendingEngine: (long) engineID;
- (void) setBlendingEngine: (long) engineID showWait:(BOOL) showWait;
- (void) getShadingValues:(float*) ambient :(float*) diffuse :(float*) specular :(float*) specularpower;
- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower;
-(void) movieChangeSource:(float*) volumeData;
-(void) movieChangeSource:(float*) volumeData showWait :(BOOL) showWait;
-(void) movieBlendingChangeSource:(long) index;
-(void) setBlendingWLWW:(float) iwl :(float) iww;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingFactor:(float) a;
//-(NSDate*) startRenderingTime;
//-(void) newStartRenderingTime;
//-(void) deleteStartRenderingTime;
-(void) setOpacity:(NSArray*) array;
- (void) setLowResolutionCamera: (Camera*) cam;
//-(void) runRendering;
//-(void) startRendering;
//-(void) stopRendering;
//- (void) autoCroppingBox;
- (float) LOD;
-(void) setLOD:(float)f;
-(void) setCurrentTool:(ToolMode) i;
- (ToolMode) currentTool;
- (ToolMode) _tool;
//- (void) resetCroppingBox;
-(id)initWithFrame:(NSRect)frame;
-(short)setPixSource:(NSMutableArray*)pix :(float*) volumeData;
-(void)dealloc;
//Fly to point in world coordinates;
- (void) flyTo:(float) x :(float) y :(float) z;
// Fly to Volume Point 
- (void) flyToVoxel:(OSIVoxel *)voxel;
//Fly to 2D position on a slice;
- (void) flyToPoint:(NSPoint)point  slice:(int)slice;
- (void) processFlyTo;
- (void) setWLWW:(float) wl :(float) ww;
- (void) getWLWW:(float*) wl :(float*) ww;
- (void) getBlendingWLWW:(float*) iwl :(float*) iww;
- (void) setBlendingPixSource:(ViewerController*) bC;
- (IBAction) endQuicktimeSettings:(id) sender;
- (IBAction) endDCMExportSettings:(id) sender;
//- (IBAction) endQuicktimeVRSettings:(id) sender;
- (IBAction) exportQuicktime :(id) sender;
- (float) rotation;
- (float) numberOfFrames;
- (void) Azimuth:(float) z;
- (void) Vertical:(float) z;
- (NSImage*) nsimageQuicktime;
- (NSImage*) nsimage:(BOOL) q;
- (void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
- (void)activateShading:(BOOL)on;
- (IBAction) switchShading:(id) sender;
- (long) shading;
- (void) setEngine: (int) engineID;
- (void) setProjectionMode: (int) mode;
- (IBAction) resetImage:(id) sender;
- (void) saView:(id) sender;
- (IBAction)setRenderMode:(id)sender;
- (void) setBlendingMode: (long) modeID;
- (NSImage*) nsimageQuicktime:(BOOL) renderingMode;
- (vtkRenderer*) vtkRenderer;
- (vtkCamera*) vtkCamera;
- (void) setVtkCamera:(vtkCamera*)aVtkCamera;
- (void)setCenterlineCamera: (Camera *) cam;
- (void) setCamera: (Camera*) cam;
- (Camera*) camera;
- (Camera*) cameraWithThumbnail:(BOOL) produceThumbnail;
- (IBAction) scissorStateButtons:(id) sender;
- (void) updateScissorStateButtons;
- (void) switchOrientationWidget:(id) sender;
- (void) computeOrientationText;
- (void) getOrientation: (float*) o;
- (void) bestRendering:(id) sender;
- (void) setMode: (long) modeID;
- (long) mode;
- (float) scaleFactor;
- (double) getResolution;
- (BOOL) getCosMatrix: (float *) cos;
- (void) getOrigin: (float *) origin;
- (void) getOrigin: (float *) origin windowCentered:(BOOL) wc;
- (void) getOrigin: (float *) origin windowCentered:(BOOL) wc sliceMiddle:(BOOL) sliceMiddle;
- (void) getOrigin: (float *) origin windowCentered:(BOOL) wc sliceMiddle:(BOOL) sliceMiddle blendedView:(BOOL) blendedView;
- (BOOL) isViewportResizable;
- (void) setViewportResizable: (BOOL) boo;
- (void) scrollInStack: (float) delta;

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
- (void) convert3Dto2Dpoint:(double*) pt3D :(double*) pt2D;
- (void)convert2DPoint:(float *)pt2D to3DPoint:(float *)pt3D;
- (IBAction) setCurrentdcmExport:(id) sender;
- (IBAction) switchToSeriesRadio:(id) sender;
- (float) offset;
- (float) valueFactor;
- (void) squareView:(id) sender;
- (void) computeValueFactor;
- (void) setRotate: (BOOL) r;
- (float) factor;
- (float) imageSampleDistance;
- (float) blendingImageSampleDistance;
- (void) setViewSizeToMatrix3DExport;
- (void) restoreViewSizeAfterMatrix3DExport;
- (void) axView:(id) sender;
- (void) coView:(id) sender;
- (void) saViewOpposite:(id) sender;
- (void) render;
- (void) renderBlendedVolume;
- (void) goToCenter;
- (void)zoomMouseUp:(NSEvent *)theEvent;
- (void) setWindowCenter: (NSPoint) loc;
- (NSPoint) windowCenter;
- (double) getClippingRangeThickness;
- (double) getClippingRangeThicknessInMm;
- (void) setClippingRangeThicknessInMm:(double) c;
- (void) setLODLow:(BOOL) l;
- (void) allocateGPUMapper;
- (void) allocateCPUMapper;

// export
- (void) sendMail:(id) sender;
- (void) exportJPEG:(id) sender;
- (void) export2iPhoto:(id) sender;
- (void) exportTIFF:(id) sender;

// cursors
-(void) setCursorForView: (ToolMode) tool;

//Dragging
- (void) startDrag:(NSTimer*)theTimer;
- (void)deleteMouseDownTimer;

//Menus
- (void)deleteRightMouseDownTimer;

-(BOOL)actionForHotKey:(NSString *)hotKey;
- (void)setAdvancedCLUT:(NSMutableDictionary*)clut lowResolution:(BOOL)lowRes;
- (void)setAdvancedCLUTWithName:(NSString*)name;
- (BOOL)advancedCLUT;
- (VRController*)controller;
- (void)setController:(VRController*)aController;
- (BOOL)isRGB;

- (vtkVolumeMapper*) mapper;
- (void)setMapper: (vtkVolumeMapper*) mapper;
- (vtkVolume*)volume;
- (void)setVolume:(vtkVolume*)aVolume;
- (char*)data8;
- (void)setData8:(char*)data;

- (void)drawImage:(NSImage *)image inBounds:(NSRect)rect;
- (BOOL)checkHasChanged;
- (void)setIChatFrame:(BOOL)boo;
//- (void)_iChatStateChanged:(NSNotification *)aNotification;

- (void)yaw:(float)degrees;
- (void)panX:(double)x Y:(double)y;

- (void)recordFlyThru;

// 3DConnexion SpaceNavigator
- (void)connect2SpaceNavigator;
void VRSpaceNavigatorMessageHandler(io_connect_t connection, natural_t messageType, void *messageArgument);

#ifdef _STEREO_VISION_
//Added SilvanWidmer 27-08-09
- (ToolMode) getTool: (NSEvent*) event;
- (void) computeLength;
- (void) generateROI;
#endif

@end
