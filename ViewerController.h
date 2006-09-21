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




#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@class DCMView;
@class OpacityTransferView;
@class ColorTransferView;
@class MyPoint;
@class ROI;
@class ThickSlabController;
@class StudyView;
@class SeriesView;
@class ImageView;
@class CurvedMPR;
@class DICOMExport;
@class KeyObjectPopupController;

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

enum
{
	eSagittalPos = 0,		// 0
	eSagittalNeg,			// 1
	eCoronalPos,			// 2
	eCoronalNeg,			// 3
	eAxialPos,				// 4
	eAxialNeg				// 5
};

@interface ViewerController : NSWindowController  <Schedulable>
{
	NSLock	*ThreadLoadImageLock;
	NSLock	*roiLock;
	
	IBOutlet StudyView		*studyView;
			SeriesView		*seriesView;

	IBOutlet NSSplitView	*splitView;
	IBOutlet NSMatrix		*previewMatrix;
	BOOL					matrixPreviewBuilt;
	
    IBOutlet NSWindow       *quicktimeWindow;
	IBOutlet NSMatrix		*quicktimeMode;
	IBOutlet NSSlider		*quicktimeInterval, *quicktimeFrom, *quicktimeTo;
	IBOutlet NSTextField	*quicktimeIntervalText, *quicktimeFromText, *quicktimeToText;
	IBOutlet NSBox			*quicktimeBox;
	
	DCMView					*imageView;
    IBOutlet NSSlider       *slider, *speedSlider;
	IBOutlet NSButton		*loopButton;
    IBOutlet NSView         *speedView;
    IBOutlet NSView         *toolsView;
    IBOutlet NSView         *WLWWView;
    IBOutlet NSView         *ReconstructionView;
	IBOutlet NSView         *ConvView;
	IBOutlet NSView         *FusionView;
	IBOutlet NSView			*BlendingView;
	IBOutlet NSView			*movieView, *serieView, *patientView, *iPhotoView, *keyImages, *PagePad;
	IBOutlet NSView         *RGBFactorsView;
	IBOutlet NSTextField    *speedText;
    IBOutlet NSPopUpButton  *wlwwPopup;
    IBOutlet NSPopUpButton  *convPopup;
    IBOutlet NSPopUpButton  *clutPopup;
	IBOutlet NSPopUpButton  *OpacityPopup;
	
	IBOutlet NSView         *subCtrlView;
			 BOOL			enableSubtraction;
	IBOutlet NSButton		*subCtrlOnOff;
			 long			subCtrlMaskID;
			 NSPoint		subCtrlMinMax;
	IBOutlet NSTextField	*subCtrlMaskText;

			 NSPoint		subCtrlOffset;
	IBOutlet NSButton		*sc1;
	IBOutlet NSButton		*sc2;
	IBOutlet NSButton		*sc3;
	IBOutlet NSButton		*sc4;
	IBOutlet NSButton		*sc5;
	IBOutlet NSButton		*sc6;
	IBOutlet NSButton		*sc7;
	IBOutlet NSButton		*sc8;
	IBOutlet NSButton		*sc9;

    IBOutlet NSSlider       *subCtrlZero;
    IBOutlet NSSlider       *subCtrlGamma;
    IBOutlet NSSlider       *subCtrlPercent;
	IBOutlet NSButton		*subCtrlSharpenButton;

			 long			speedometer;
		 
	IBOutlet NSView			*StatusView;
	IBOutlet NSButton		*CommentsField;
	IBOutlet NSPopUpButton	*StatusPopup;
	IBOutlet NSWindow		*CommentsWindow;
	IBOutlet NSTextField    *CommentsEditField;
	
	IBOutlet NSButton		*keyImageDisplay;
	IBOutlet NSButton		*keyImageCheck;
	
	
	IBOutlet NSWindow		*ThickIntervalWindow;
    IBOutlet NSTextField    *customInterval;
    IBOutlet NSTextField    *customXSpacing;
	IBOutlet NSTextField    *customYSpacing;
	IBOutlet NSMatrix		*customVectors, *customOrigin;

    IBOutlet NSWindow       *setWLWWWindow;
    IBOutlet NSTextField    *wlset, *fromset;
    IBOutlet NSTextField    *wwset, *toset;
			
    IBOutlet NSWindow       *addWLWWWindow;
    IBOutlet NSTextField    *newName;
    IBOutlet NSTextField    *wl;
    IBOutlet NSTextField    *ww;
	IBOutlet NSMatrix		*toolsMatrix;
    
	IBOutlet NSWindow       *roiSetPixWindow;
	IBOutlet NSTextField    *maxValueText, *minValueText, *newValueText;
	IBOutlet NSMatrix		*InOutROI, *AllROIsRadio;
	IBOutlet NSButton		*checkMaxValue, *checkMinValue, *setROI4DSeries;

	IBOutlet NSWindow       *curvedMPRWindow;
	IBOutlet NSTextField	*curvedMPRtext;
	IBOutlet NSSlider		*curvedMPRslid;
	IBOutlet NSButton		*curvedMPRper;
	IBOutlet NSSlider		*curvedMPRsize;
	IBOutlet NSTextField	*curvedMPRsizeText;
	IBOutlet NSSlider		*curvedMPRinterval;
	IBOutlet NSTextField	*curvedMPRintervalText;
	
	IBOutlet NSWindow       *blendingTypeWindow;
	IBOutlet NSButton		*blendingTypeMultiply, *blendingTypeSubtract;
	IBOutlet NSButton		*blendingTypeRed, *blendingTypeGreen, *blendingTypeBlue, *blendingTypeRGB;
	IBOutlet NSPopUpButton  *blendingPlugins;
	
	IBOutlet NSWindow       *roiPropaWindow;
	IBOutlet NSMatrix		*roiPropaMode, *roiPropaDim, *roiPropaCopy;
	IBOutlet NSTextField	*roiPropaDest;
	
	IBOutlet NSWindow       *addConvWindow;
	IBOutlet NSMatrix		*convMatrix, *sizeMatrix;
	IBOutlet NSTextField    *matrixName, *matrixNorm;
	
	IBOutlet NSWindow       *addCLUTWindow;
	IBOutlet NSTextField    *clutName;
	IBOutlet ColorTransferView  *clutView;

	IBOutlet NSWindow       *dcmExportWindow;
	IBOutlet NSMatrix		*dcmSelection, *dcmFormat;
	IBOutlet NSSlider		*dcmInterval, *dcmFrom, *dcmTo;
	IBOutlet NSTextField	*dcmIntervalText, *dcmFromText, *dcmToText;
	IBOutlet NSBox			*dcmBox;
	IBOutlet NSTextField	*dcmSeriesName;
	
	IBOutlet NSWindow       *imageExportWindow;
	IBOutlet NSMatrix		*imageSelection, *imageFormat;
	
	IBOutlet NSWindow		*displaySUVWindow;
	IBOutlet NSForm			*suvForm;
	IBOutlet NSMatrix		*suvConversion;
	
	IBOutlet NSWindow       *addOpacityWindow;
	IBOutlet NSTextField    *OpacityName;
	IBOutlet OpacityTransferView  *OpacityView;
	
	IBOutlet NSTextField    *movieTextSlide;
	IBOutlet NSButton		*moviePlayStop;
	IBOutlet NSSlider       *movieRateSlider;
	IBOutlet NSSlider       *moviePosSlider;
	
	IBOutlet NSTextField    *blendingPercentage;
	IBOutlet NSSlider       *blendingSlider;
	ViewerController		*blendingController;
	
	IBOutlet NSTextField    *roiRenameName;
	IBOutlet NSMatrix		*roiRenameMatrix;
	IBOutlet NSWindow		*roiRenameWindow;
	
	NSString				*curConvMenu, *curWLWWMenu, *curCLUTMenu, *curOpacityMenu;
	
	IBOutlet NSTextField    *stacksFusion;
	IBOutlet NSSlider       *sliderFusion;
	IBOutlet NSPopUpButton  *popFusion, *popupRoi, *ReconstructionRoi;
	
	IBOutlet NSMatrix		*buttonToolMatrix;
	
	NSMutableArray			*fileList[200];
    NSMutableArray          *pixList[200], *roiList[200];
	NSData					*volumeData[200];
	short					curMovieIndex, maxMovieIndex, orientationVector;
    NSToolbar               *toolbar;
	
	float					direction;
	
	volatile float			loadingPercentage;
    
	volatile BOOL			ThreadLoadImage, stopThreadLoadImage, loadingPause;
    BOOL                    FullScreenOn;
    NSWindow                *FullScreenWindow;
    NSWindow                *StartingWindow;
    NSView                  *contentView;
    
    NSTimer					*timer, *movieTimer, *timeriChat;
    NSTimeInterval			lastTime, lastTimeFrame;
	NSTimeInterval			lastMovieTime;
	
	NSMutableArray			*ROINamesArray;
	
	ThickSlabController		*thickSlab;
	
	CurvedMPR				*curvedController;
	
	DICOMExport				*exportDCM;
	
	BOOL					windowWillClose;
	
	NSRect					standardRect;
	
	// Brush ROI Filter
	IBOutlet NSWindow		*brushROIFilterOptionsWindow;
	IBOutlet NSSlider		*structuringElementRadiusSlider;
	IBOutlet NSTextField	*structuringElementRadiusTextField;
	IBOutlet NSButton		*brushROIFilterOptionsAllWithSameName;
	IBOutlet NSButton		*brushROIFilterOptionsOKButton;
	IBOutlet NSPopUpButton	*keyImagePopUpButton;
	
	KeyObjectPopupController *keyObjectPopupController;
	BOOL					displayOnlyKeyImages;
}

// Create a new 2D Viewer
+ (ViewerController *) newWindow:(NSMutableArray*)pixList :(NSMutableArray*)fileList :(NSData*) volumeData;
- (ViewerController *) newWindow:(NSMutableArray*)pixList :(NSMutableArray*)fileList :(NSData*) volumeData;
- (void) CloseViewerNotification: (NSNotification*) note;

// Return the 'dragged' window, the destination window is contained in the 'viewerController' object of the 'PluginFilter' object
-(ViewerController*) blendedWindow;

// Display a waiting window
- (id) startWaitWindow :(NSString*) message;

- (id) startWaitProgressWindow :(NSString*) message :(long) max;
- (void) waitIncrementBy:(id) waitWindow :(long) val;

- (void) endWaitWindow:(id) waitWindow;

// Refresh the current displayed image
- (void) needsDisplayUpdate;

// Return the memory pointer that contains the ENTIRE series (a unique memory block for all images)
- (float*) volumePtr;
- (float*) volumePtr: (long) i;

// Return the index into fileList that coresponds to the index in pixList
- (long) indexForPix: (long) pixIndex;

// Return the image pane object
- (DCMView*) imageView;

// Return the array of DCMPix objects
- (NSMutableArray*) pixList;
- (NSMutableArray*) pixList: (long) i;

// Return the array of DicomFile objects
- (NSMutableArray*) fileList;

// Return the array of ROI objects
- (NSMutableArray*) roiList;

// Create a new Point object
- (MyPoint*) newPoint: (float) x :(float) y;

// Create a new ROI object
- (ROI*) newROI: (long) type;

// Delete ALL ROIs of current series
- (IBAction) roiDeleteAll:(id) sender;

// methods to access global variables
+ (long) numberOf2DViewer;

// UNDOCUMENTED FUNCTIONS
// For more informations: rossetantoine@bluewin.ch

- (IBAction) startMSRG:(id) sender;
- (IBAction) startMSRGWithAutomaticBounding:(id) sender;
//arg: this function will automatically scan the buffer to create a textured ROI (tPlain) for all slices
// param forValue: this param defines the region to extract in the stack buffer
- (void)addRoiFromFullStackBuffer:(unsigned char*)buff forSpecificValue:(unsigned char)value withColor:(RGBColor)aColor;
- (void)addRoiFromFullStackBuffer:(unsigned char*)buff forSpecificValue:(unsigned char)value withColor:(RGBColor)aColor withName:(NSString*)name;
//arg: Use this to extract all the rois from the
- (void)addRoiFromFullStackBuffer:(unsigned char*)buff;
- (void)addPlainRoiToCurrentSliceFromBuffer:(unsigned char*)buff;
- (void)addRoiFromFullStackBuffer:(unsigned char*)buff withName:(NSString*)name;
- (void)addPlainRoiToCurrentSliceFromBuffer:(unsigned char*)buff withName:(NSString*)name;
-(void)addPlainRoiToCurrentSliceFromBuffer:(unsigned char*)buff forSpecificValue:(unsigned char)value withColor:(RGBColor)aColor withName:(NSString*)name;
- (NSLock*) roiLock;
- (void) brushTool:(id) sender;
- (IBAction) setButtonTool:(id) sender;
- (void) setLoadingPause:(BOOL) lp;
- (void) setImageIndex:(long) i;
- (IBAction) ConvertToRGBMenu:(id) sender;
- (IBAction) ConvertToBWMenu:(id) sender;
- (IBAction) export2PACS:(id) sender;

- (IBAction) subCtrlOnOff:(id) sender;
- (IBAction) subCtrlNewMask:(id) sender;
- (IBAction) subCtrlOffset:(id) sender;
- (IBAction) subCtrlSliders:(id) sender;
- (int) threeTestsFivePosibilities: (int) f;
- (void) offsetMatrixSetting: (int) twentyFiveCodes;
- (IBAction) subSumSlider:(id) sender;
- (IBAction) subSharpen:(id) sender;

- (void) loadROI:(long) mIndex;
- (void) saveROI:(long) mIndex;
- (id) findPlayStopButton;
- (IBOutlet)setKeyImage:(id)sender;
- (BOOL) FullScreenON;
- (void) setROITool:(id) sender;
- (void) setROITool:(int) roitype name :(NSString*) title;
- (void) changeImageData:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v :(BOOL) applyTransition;
- (IBAction) loadSerie:(id) sender;
- (IBAction) loadPatient:(id) sender;
- (void) offFullScreen;
- (float) frame4DRate;
- (long) maxMovieIndex;
- (NSSlider*) moviePosSlider;
- (NSSlider*) sliderFusion;
- (IBAction) convMatrixAction:(id)sender;
- (IBAction) changeMatrixSize:(id) sender;
- (IBAction) computeSum:(id) sender;
- (IBAction) endNameWLWW:(id) sender;
- (IBAction) endSetWLWW:(id) sender;
- (IBAction) updateSetWLWW:(id) sender;
- (IBAction) endConv:(id) sender;
- (IBAction) endCLUT:(id) sender;
- (IBAction) endBlendingType:(id) sender;
- (IBAction) endQuicktime:(id) sender;
- (void) setDefaultTool:(id) sender;
- (OSErr)getFSRefAtPath:(NSString*)sourceItem ref:(FSRef*)sourceRef;
- (id) viewCinit:(NSMutableArray*)f :(NSMutableArray*) d :(NSData*) v;
- (void) setPixelList:(NSMutableArray*)f fileList:(NSMutableArray *)d volumeData:(NSData *) v;
- (void) speedSliderAction:(id) sender;
- (void) setupToolbar;
- (void) PlayStop:(id) sender;
- (short) getNumberOfImages;
- (float) frameRate;
- (void) adjustSlider;
- (void) sliderFusionAction:(id) sender;
- (void) popFusionAction:(id) sender;
- (void) propagateSettings;
- (void) setCurWLWWMenu:(NSString*)s ;
- (BOOL) is2DViewer;
- (NSString*) curCLUTMenu;
- (NSString*) curWLWWMenu;
- (BOOL) windowWillClose;
- (void) ApplyCLUTString:(NSString*) str;
- (NSSlider*) blendingSlider;
- (void) blendingSlider:(id) sender;
- (void) blendingMode:(id) sender;
- (ViewerController*) blendingController;
- (NSString*) modality;
- (void) addMovieSerie:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v;
- (void) startLoadImageThread;
- (void) moviePosSliderAction:(id) sender;
- (void) movieRateSliderAction:(id) sender;
- (void) MoviePlayStop:(id) sender;
- (void) checkEverythingLoaded;
- (BOOL) isEverythingLoaded;
- (IBAction) roiSetPixelsSetup:(id) sender;
- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL)propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue;
- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL)propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue :(BOOL) updateVolumeData;
- (IBAction) roiSetPixels:(id) sender;
- (IBAction) roiPropagateSetup: (id) sender;
- (IBAction) roiPropagate:(id) sender;
- (void) showWindowTransition;
- (float) computeInterval;
- (IBAction) endThicknessInterval:(id) sender;
- (void) SetThicknessInterval:(id) constructionType;
- (IBAction) MPRViewer:(id) sender;
- (IBAction) VRVPROViewer:(id) sender;
- (IBAction) VRViewer:(id) sender;
- (IBAction) MPR2DViewer:(id) sender;
- (IBAction) orthogonalMPRViewer:(id) sender;
- (IBAction) endoscopyViewer:(id) sender;
- (IBAction) CurvedMPR:(id) sender;
//- (IBAction) MIPViewer:(id) sender;
- (IBAction) SRViewer:(id) sender;
- (void)createDCMViewMenu;
- (void) exportJPEG:(id) sender;
- (void)closeAllWindows:(NSNotification *)note;
- (NSMutableArray*) generateROINamesArray;
- (ThickSlabController*) thickSlabController;
- (IBAction) AddOpacity:(id) sender;
- (IBAction) endOpacity:(id) sender;
- (IBAction) updateImage:(id) sender;
//- (IBAction) HuVRViewer:(id) sender;
- (IBAction) clutAction:(id)sender;
- (void) tileWindows;
-(IBAction) export2iPhoto:(id) sender;
-(IBAction) PagePadCreate:(id) sender;
- (void) exportQuicktime:(id) sender;
- (IBAction) exportQuicktimeSlider:(id) sender;
- (IBAction) exportDICOMSlider:(id) sender;;
- (IBAction) setComments:(id) sender;
- (IBAction) setStatus:(id) sender;
- (IBAction) endSetComments:(id) sender;
- (void) setMovieIndex: (short) i;
- (void) setCurvedController: (CurvedMPR*) cmpr;
- (CurvedMPR*) curvedController;
- (IBAction) setCurvedMPRslider:(id) sender;
- (IBAction) endCurvedMPR:(id) sender;
- (IBAction) resetImage:(id) sender;
+ (NSArray*) defaultROINames;
+ (void) setDefaultROINames: (NSArray*) names;
- (IBAction) endExportDICOMFileSettings:(id) sender;
- (IBAction) keyImageCheckBox:(id) sender;
- (IBAction) keyImageDisplayButton:(id) sender;
- (void) adjustKeyImage;
- (void) buildMatrixPreview;
- (void) matrixPreviewSelectCurrentSeries;
- (void) autoHideMatrix;
- (void) exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval;
- (IBAction) endExportImage: (id) sender;
- (IBAction) setCurrentPosition:(id) sender;
- (IBAction) setCurrentdcmExport:(id) sender;
- (IBAction) endDisplaySUV:(id) sender;
- (IBAction) endRoiRename:(id) sender;
- (IBAction) roiRename:(id) sender;
- (void) SyncSeries:(id) sender;
- (float) computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts error:(NSString**) error;
- (NSArray*) roisWithName: (NSString*) name;
- (NSArray*) roiNames;
- (void) deleteSeriesROIwithName: (NSString*) name;
- (void) renameSeriesROIwithName: (NSString*) name newName:(NSString*) newName;
- (void)setStandardRect:(NSRect)rect;
- (void)setWindowFrame:(NSRect)rect;
- (IBAction) Panel3D:(id) sender;
- (void) revertSeries:(id) sender;
- (NSImage*) imageForROI: (int) i;
- (void) ActivateBlending:(ViewerController*) bC;
- (void) setFusionMode:(long) m;
- (short) curMovieIndex;
- (id) findiChatButton;
- (void) convertPETtoSUV;
- (IBAction) fullScreenMenu:(id) sender;
- (void)exportTextFieldDidChange:(NSNotification *)note;
- (short) orientationVector;
// functions s that plugins can also play with globals
+ (ViewerController *) draggedController;
+ (void) setDraggedController:(ViewerController *) controller;
- clear8bitRepresentations;
-(void) ApplyConvString:(NSString*) str;
- (void)checkView:(NSView *)aView :(BOOL) OnOff;

#pragma mark-
#pragma mark Brush ROI Filters

- (void) applyMorphology: (NSArray*) rois action:(NSString*) action	radius: (long) radius sendNotification: (BOOL) sendNotification;

- (ROI*) selectedROI;

- (IBAction) setStructuringElementRadius: (id) sender;
- (IBAction) closeBrushROIFilterOptionsSheet: (id) sender;

- (IBAction) erodeSelectedBrushROIWithRadius: (id) sender;
- (IBAction) erodeSelectedBrushROI: (id) sender;
- (IBAction) dilateSelectedBrushROIWithRadius: (id) sender;
- (IBAction) dilateSelectedBrushROI: (id) sender;
- (IBAction) closeSelectedBrushROIWithRadius: (id) sender;
- (IBAction) closeSelectedBrushROI: (id) sender;

#pragma mark-
#pragma mark Registration

- (NSMutableArray*) point2DList;
- (void) computeRegistrationWithMovingViewer:(ViewerController*) movingViewer;

#pragma mark-
#pragma mark Key Objects
- (IBAction)createKeyObjectNote:(id)sender;
- (void)keyObjectSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (IBAction)keyObjectNotes:(id)sender;
- (BOOL)displayOnlyKeyImages;
- (BOOL)isKeyImage:(int)index;

@end
