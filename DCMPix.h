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

//7/7/05 Fixed bug with DCM Framework and WW and WC. Use float value rather than int value. LP

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

#define USEVIMAGE

typedef struct {
   double x,y,z;
} XYZ;

extern XYZ ArbitraryRotate(XYZ p,double theta,XYZ r);

@class xNSImage;
@class ROI;
@class ThickSlabController;
@class DCMObject;

@interface DCMPix: NSObject <NSCopying>
{
//SOURCES
	NSString            *srcFile;
	BOOL				isBonjour;
	BOOL				nonDICOM;

//BUFFERS	
	NSArray				*pixArray;
    NSManagedObject		*imageObj;	
    xNSImage			*image;
    short               *oImage;
	float				*fImage, *fVolImage;
    char                *wImage;
	
//DICOM TAGS

//	orientation
	double				originX, originY, originZ;
	double				orientation[ 9];

//	pixel representation
	BOOL				fIsSigned;
	short				bitsAllocated, bitsStored, spp;
    float               slope, offset;

//	image size
    long                height, width, rowBytes;

//	window level & width
	float				savedWL, savedWW;

//	planar configuration
	long				fPlanarConf;
    double               pixelSpacingX, pixelSpacingY, pixelRatio;

//	photointerpretation
	BOOL				isRGB;
	BOOL				inverseVal;

//--------------------------------------

// DICOM params needed for SUV calculations
	float				patientsWeight;
	NSString			*repetitiontime;
	NSString			*echotime;
	NSString			*flipAngle, *laterality;
	NSString			*protocolName;
	NSString			*viewPosition;
	NSString			*patientPosition;
	BOOL				hasSUV, SUVConverted;
	NSString			*units, *decayCorrection;
	float				decayFactor;
	float				radionuclideTotalDose;
	float				radionuclideTotalDoseCorrected;
	NSCalendarDate		*acquisitionTime;
	NSCalendarDate		*radiopharmaceuticalStartTime;
	float				halflife;
    float				philipsFactor;
	BOOL				displaySUVValue;

// DICOM params for Overlays - 0x6000 group	
	int					oRows, oColumns, oType, oOrigin[ 2], oBits, oBitPosition;
	unsigned char		*oData;
	
//	DSA-subtraction	
	float				*subtractedfImage;
	NSPoint				subPixOffset;
	NSPoint				subMinMax;
	float				subtractedfPercent;
	float				subtractedfZ;
	float				subtractedfZero;
	float				subtractedfGamma;
	GammaFunction		subGammaFunction;
	
	long				maskID;
	float				maskTime;
	float				fImageTime;
	//float				rot;
	//float				ang;
	NSNumber			*positionerPrimaryAngle;
	NSNumber			*positionerSecondaryAngle;
	
	long				shutterRect_x;
	long				shutterRect_y;
	long				shutterRect_w;
	long				shutterRect_h;
	
	long				shutterCircular_x;
	long				shutterCircular_y;
	long				shutterCircular_radius;
	
	NSPoint	 			*shutterPolygonal;
	long				shutterPolygonalSize;
	
	BOOL				DCMPixShutterOnOff;

//-------------------------------------------------------	
	long				frameNo;
	long				serieNo;
	long				imID, imTot;    
    char                *baseAddr;

//convolution	
	BOOL				convolution, updateToBeApplied;
	short				kernelsize;
	short				normalization;
	short				kernel[25];

	float				cineRate;

//slice
    double				sliceInterval, sliceLocation, sliceThickness;
	double				spacingBetweenSlices;								//SpacingBetweenSlices (0018,0088)
	
//stack
	short				stack;
	short				stackMode, pixPos, stackDirection;
//thickslab
    BOOL				thickSlabVRActivated;
	ThickSlabController *thickSlab;
	
	float				countstackMean;
    float				ww, wl;
	float				fullww, fullwl;
	BOOL				fixed8bitsWLWW;	
    float               maxValueOfSeries, minValueOfSeries;
	
	
	NSString			*convertedDICOM;	
	BOOL				generated;	
	NSLock				*checking;
	NSLock				*processorsLock;
	volatile int		numberOfThreadsForCompute;
	
	BOOL				useVOILUT;
	int					VOILUT_first;
	unsigned int		VOILUT_number, VOILUT_depth, *VOILUT_table;
	
	char				blackIndex;
	
	NSData				*transferFunction;
	float				*transferFunctionPtr;
	
// custom annotations
	NSMutableDictionary *annotationsDictionary;
	NSMutableDictionary *cachedPapyGroups;
}

@property long frameNo;
@property(setter=setID:) long ID;

@property float minValueOfSeries, maxValueOfSeries;

// Dimensions in pixels
@property long pwidth, pheight;

// Is it an RGB image (ARGB) or float image?
@property(setter=setRGB:) BOOL isRGB; // Note setter is different to not break existing usage. :-(

// Pointer to image data
@property(setter=setfImage:) float* fImage;

// WW & WL
@property(readonly) float ww, wl, fullww, fullwl;
@property float savedWW, savedWL;

@property(readonly) float slope, offset;

// X/Y ratio - non-square pixels
@property double pixelRatio;

// pixel size
@property double pixelSpacingX, pixelSpacingY;

// Slice orientation
- (void)orientation:(float*) c;
- (void)setOrientation:(float*) c;

- (void)orientationDouble:(double*) c;
- (void)setOrientationDouble:(double*) c;

// Slice location
@property(readonly) double originX, originY, originZ;

- (void)setOrigin :(float*) o;
- (void)setOriginDouble :(double*) o;

// Thickness/Axial Location
@property double sliceLocation;
@property double sliceThickness;
@property double sliceInterval;
@property(readonly) double spacingBetweenSlices;

// 8-bit TransferFunction
@property(retain) NSData *transferFunction; 

@property NSPoint subPixOffset;

@property long DCMPixShutterRectWidth, DCMPixShutterRectHeight;
@property long DCMPixShutterRectOriginX, DCMPixShutterRectOriginY;

@property(copy) NSString *repetitiontime, *echotime;
@property(readonly) NSString *flipAngle, *laterality;

@property(readonly) NSString *protocolName;
@property(readonly) NSString *viewPosition;
@property(readonly) NSString *patientPosition;

@property char* baseAddr;

@property long rowBytes;
@property(readonly) long serieNo;

@property(getter=Tot, setter=setTot:) long Tot;

@property(readonly) short stack, stackMode;
@property(readonly) BOOL generated;
@property(copy) NSString *sourceFile;

//Database links
@property(readonly) NSManagedObject *imageObj, *seriesObj;
@property(readonly) NSString *srcFile;
@property(readonly) NSMutableDictionary *annotationsDictionary;

// Properties (aka accessors) needed for SUV calculations
@property(readonly) float philipsFactor;
@property float patientsWeight;
@property float halflife;
@property float radionuclideTotalDose;
@property float radionuclideTotalDoseCorrected;
@property(retain) NSCalendarDate *acquisitionTime;
@property(retain) NSCalendarDate *radiopharmaceuticalStartTime;
@property BOOL SUVConverted;
@property(readonly) BOOL hasSUV;
@property float decayFactor;
@property(copy) NSString *units, *decayCorrection;
@property BOOL displaySUVValue;

- (void) copySUVfrom: (DCMPix*) from;
- (float) getPixelValueX: (long) x Y:(long) y;

- (void) checkSUV;

+ (void) checkUserDefaults: (BOOL) update;
+ (void) resetUserDefaults;
+ (BOOL) IsPoint:(NSPoint) x inPolygon:(NSPoint*) poly size:(int) count;


- (void) changeWLWW:(float)newWL :(float)newWW;
- (void) computePixMinPixMax;

// Compute ROI data
- (int)calciumCofactorForROI:(ROI *)roi threshold:(int)threshold;
- (void) computeROI:(ROI*) roi :(float *)mean :(float *)total :(float *)dev :(float *)min :(float *)max;
- (void) computeROIInt:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max;

// Fill a ROI with a value!
- (void) fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition;
- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo :(BOOL) restore;
- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientation :(long) stackNo;
- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside;

- (unsigned char*) getMapFromPolygonROI:(ROI*) roi;

// Is this Point (pt) in this ROI ?
- (BOOL) isInROI:(ROI*) roi :(NSPoint) pt;

// Return a pointer with all pixels values contained in the current ROI
// Free the pointer with the free() function
- (float*) getROIValue :(long*) numberOfValues :(ROI*) roi :(float**) locations;
- (float*) getLineROIValue :(long*) numberOfValues :(ROI*) roi;


// Utility methods to convert user supplied pixel coords to DICOM patient coords float d[3] (in mm)
// using current slice location and orientation and vice versa
-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d;
-(void) convertPixDoubleX: (double) x pixY: (double) y toDICOMCoords: (double*) d;

-(void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc;
-(void) convertDICOMCoordsDouble: (double*) dc toSliceCoords: (double*) sc;

+(int) nearestSliceInPixelList: (NSArray*)pixlist withDICOMCoords: (float*)dc sliceCoords: (float*) sc;  // Return index & sliceCoords



- (BOOL) thickSlabVRActivated;
- (void) ConvertToBW:(long) mode;
- (void) ConvertToRGB:(long) mode :(long) cwl :(long) cww;
- (float) cineRate;

// drag-drop subtraction-multiplication between series
- (void) imageArithmeticMultiplication:(DCMPix*) sub;
- (float*) multiplyImages :(float*) input :(float*) subfImage;
- (void) imageArithmeticSubtraction:(DCMPix*) sub;
- (float*) arithmeticSubtractImages :(float*) input :(float*) subfImage;

//DSA
- (void) setSubSlidersPercent: (float) p gamma: (float) g zero: (float) z;
- (void) setSubSlidersPercent: (float) p;
- (NSPoint) subMinMax:(float*)input :(float*)subfImage;
- (void) setSubtractedfImage:(float*)mask :(NSPoint)smm;
- (float*) subtractImages:(float*)input :(float*)subfImage;

-(void) fImageTime:(float)newTime;
-(float) fImageTime;
-(void) maskID:(long)newID;
-(long) maskID;
-(void) maskTime:(float)newMaskTime;
-(float) maskTime;
-(void) positionerPrimaryAngle:(NSNumber *)newPositionerPrimaryAngle;
-(NSNumber*) positionerPrimaryAngle;
-(void) positionerSecondaryAngle:(NSNumber*)newPositionerSecondaryAngle;
-(NSNumber*) positionerSecondaryAngle;
+ (NSPoint) originDeltaBetween:(DCMPix*) pix1 And:(DCMPix*) pix2;
- (void) setBlackIndex:(int) i;
+ (NSImage*) resizeIfNecessary:(NSImage*) currentImage dcmPix: (DCMPix*) dcmPix;
-(void) DCMPixShutterRect:(long)x:(long)y:(long)w:(long)h;
-(BOOL) DCMPixShutterOnOff;
-(void) DCMPixShutterOnOff:(BOOL)newDCMPixShutterOnOff;
- (void) computeTotalDoseCorrected;
- (void) copyFromOther:(DCMPix *) fromDcm;
- (void) imageArithmeticMultiplication:(DCMPix*) sub;
- (void) setRGB : (BOOL) val;
- (void) setConvolutionKernel:(short*)val :(short) size :(short) norm;
- (void) applyConvolutionOnSourceImage;
- (void) setArrayPix :(NSArray*) array :(short) i;
- (BOOL) updateToApply;
- (id) myinitEmpty;
- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss;
- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO;
- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ;
- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize;
- (NSImage*) computeWImage: (BOOL) smallIcon :(float)newWW :(float)newWL;
- (NSImage*) image;
- (NSImage*) getImage;
- (void) orientation:(float*) c;
- (void) setOrientation:(float*) c;
- (short*) oImage;
- (void) kill8bitsImage;
- (void) checkImageAvailble:(float)newWW :(float)newWL;
- (BOOL)loadDICOMDCMFramework;
- (BOOL) loadDICOMPapyrus;
- (void) CheckLoadIn;
- (void) CheckLoad;
- (float*) computefImage;
-(void) setFusion:(short) m :(short) s :(short) direction;
-(void) setUpdateToApply;
- (void) setUpdateToApply;
- (void)revert;
- (void) computePixMinPixMax;
- (void) setThickSlabController:( ThickSlabController*) ts;
- (void) setFixed8bitsWLWW:(BOOL) f;
- (void) prepareRestore;
- (void) freeRestore;
+ (void) setRunOsiriXInProtectedMode:(BOOL) v;
+ (BOOL) isRunOsiriXInProtectedModeActivated;
- (void) clearCachedPapyGroups;
- (void *) getPapyGroup: (int) group fileNb: (int) fileNb;

//RTSTRUCT
- (void)createROIsFromRTSTRUCT: (DCMObject*)dcmObject;

@end
