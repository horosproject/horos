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
	
	NSPoint				independentOffset;
	float				independentRotation, independentZoom;
	
	NSData				*transferFunction;
	float				*transferFunctionPtr;
	
// custom annotations
	NSMutableDictionary *annotationsDictionary;
}

+ (void) checkUserDefaults: (BOOL) update;
+ (void) resetUserDefaults;
+ (BOOL) IsPoint:(NSPoint) x inPolygon:(NSPoint*) poly size:(int) count;

// Is it an RGB image (ARGB) or float image?
- (BOOL) isRGB;

// Pointer to image data
- (float*) fImage;

// Dimensions in pixels
- (long) setPwidth:(long) w;
- (long) pwidth;

- (long) setPheight:(long) h;
- (long) pheight;

// WL & WW
- (float) ww;
- (float) wl;
-(float) fullww;
-(float) fullwl;
- (float) savedWL;
- (float) savedWW;
- (float) setSavedWL:(float) l;
- (float) setSavedWW:(float) w;
- (void) changeWLWW:(float)newWL :(float)newWW;
-(void) computePixMinPixMax;
- (float) maxValueOfSeries;
- (void) setMaxValueOfSeries: (float) f;
- (float) minValueOfSeries;
- (void) setMinValueOfSeries: (float) f;
-(NSPoint) independentOffset;
-(void) setIndependentOffset:(NSPoint) z;
-(float) independentRotation;
-(void) setIndependentRotation:(float) z;
-(float) independentZoom;
-(void) setIndependentZoom:(float) z;
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

// X/Y ratio - non-square pixels
-(void) setPixelRatio:(float)r;
-(double) pixelRatio;

// pixel size
-(double) pixelSpacingX;
-(double) pixelSpacingY;
-(void) setPixelSpacingX :(double) s;
-(void) setPixelSpacingY :(double) s;

// 8-bit TransferFunction
- (NSData*) transferFunction;
- (void) setTransferFunction:(NSData*) tf;

// Slice orientation
-(void) orientation:(float*) c;
-(void) setOrientation:(float*) c;

-(void) orientationDouble:(double*) c;
-(void) setOrientationDouble:(double*) c;

// Slice location
-(double) originX;
-(double) originY;
-(double) originZ;
-(void) setOrigin :(float*) o;
-(void) setOriginDouble :(double*) o;

// Utility methods to convert user supplied pixel coords to DICOM patient coords float d[3] (in mm)
// using current slice location and orientation and vice versa
-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d;
-(void) convertPixDoubleX: (double) x pixY: (double) y toDICOMCoords: (double*) d;

-(void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc;
-(void) convertDICOMCoordsDouble: (double*) dc toSliceCoords: (double*) sc;

+(int) nearestSliceInPixelList: (NSArray*)pixlist withDICOMCoords: (float*)dc sliceCoords: (float*) sc;  // Return index & sliceCoords

// Thickness/Axial Location
-(double) sliceLocation;
-(void) setSliceLocation:(float) l;
-(double) sliceThickness;
-(void) setSliceThickness:(float) l;
-(double) sliceInterval;
-(void) setSliceInterval :(float) s;
-(double) spacingBetweenSlices;

// ID / FrameNo
-(long) ID;
- (void) setID :(long) i;
- (long) frameNo;
- (void) setFrameNo:(long) f;
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
- (NSPoint) subPixOffset;
- (void) setSubPixOffset:(NSPoint) subOffset;
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
-(long) DCMPixShutterRectWidth;
-(long) DCMPixShutterRectHeight;
-(long) DCMPixShutterRectOriginX;
-(long) DCMPixShutterRectOriginY;
-(BOOL) DCMPixShutterOnOff;
-(void) DCMPixShutterOnOff:(BOOL)newDCMPixShutterOnOff;
- (void) computeTotalDoseCorrected;
- (void) copyFromOther:(DCMPix *) fromDcm;
- (void) imageArithmeticMultiplication:(DCMPix*) sub;
- (NSString*) repetitiontime;
- (NSString*) echotime;
- (NSString*) flipAngle;
- (NSString*) laterality;
- (void) setRepetitiontime:(NSString*)rep;
- (void) setEchotime:(NSString*)echo;
- (NSString*) protocolName;
- (NSString*) viewPosition;
- (NSString*) patientPosition;
- (void) setRGB : (BOOL) val;
- (void) setConvolutionKernel:(short*)val :(short) size :(short) norm;
- (void) applyConvolutionOnSourceImage;
- (void) setArrayPix :(NSArray*) array :(short) i;
- (BOOL) updateToApply;
- (id) myinitEmpty;
- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss;
/*		s == File Path
		pos == Image ID (Number)
		tot == number of IMages?
		ptr == ptr to volume
		f == frame number
		ss == series number
		hello == Bonjour
		imageObj (iO) == image core data object

- (id) initWithContentsOfFile:(NSString*) s 
							imageID:(long) pos 
							numberOfImages:(long) tot 
							volume:(float*) ptr 
							frameNumber:(long) f 
							seriesNumber:(long) ss 
							isBonjour:(BOOL) hello 
					imageObj: (NSManagedObject*) iO;
*/					
- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO;
- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ;
- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize;
- (NSImage*) computeWImage: (BOOL) smallIcon :(float)newWW :(float)newWL;
- (NSImage*) image;
- (NSImage*) getImage;
- (char*) baseAddr;
- (void) setBaseAddr :( char*) ptr;
- (void) orientation:(float*) c;
- (void) setOrientation:(float*) c;
- (short*) oImage;
- (void) kill8bitsImage;
- (void) checkImageAvailble:(float)newWW :(float)newWL;
-(long) rowBytes;
-(void) setRowBytes:(long) rb;
- (BOOL)loadDICOMDCMFramework;
- (BOOL) loadDICOMPapyrus;
- (void) CheckLoadIn;
- (void) CheckLoad;
- (float*) computefImage;
-(float) slope;
-(float) offset;
-(long) serieNo;
-(long) Tot;
-(void) setTot: (long) tot;
-(void) setFusion:(short) m :(short) s :(short) direction;
-(short) stack;
-(short) stackMode;
- (long) rowBytes;
- (void) setRowBytes:(long) rb;
- (float) fullww;
- (float) fullwl;
- (void)setSourceFile:(NSString*)s;
-(NSString*) sourceFile;
-(void) setUpdateToApply;
-(void) revert;
- (NSString*) sourceFile;
- (void) setUpdateToApply;
- (void) revert;
- (void) computePixMinPixMax;
- (void) setfImage:(float*) ptr;
- (void) setThickSlabController:( ThickSlabController*) ts;
- (void) setFixed8bitsWLWW:(BOOL) f;
- (BOOL) generated;
- (void) prepareRestore;
- (void) freeRestore;
+ (void) setRunOsiriXInProtectedMode:(BOOL) v;
+ (BOOL) isRunOsiriXInProtectedModeActivated;

//Database links
- (NSManagedObject *)imageObj;
- (NSManagedObject *)seriesObj;

// Accessor methods needed for SUV calculations
- (float) philipsFactor;
- (float) patientsWeight;
- (void) setPatientsWeight : (float) v;
- (float) halflife;
- (void) setHalflife : (float) v;
- (float) radionuclideTotalDose;
- (void) setRadionuclideTotalDose : (float) v;
- (float) radionuclideTotalDoseCorrected;
- (void) setRadionuclideTotalDoseCorrected : (float) v;
- (NSCalendarDate*) acquisitionTime;
- (void) setAcquisitionTime : (NSCalendarDate*) d;
- (NSCalendarDate*) radiopharmaceuticalStartTime;
- (void) setRadiopharmaceuticalStartTime : (NSCalendarDate*) d;
- (void) setSUVConverted : (BOOL) v;
- (BOOL) SUVConverted;
- (float) decayFactor;
- (float) setDecayFactor: (float) f;
- (NSString*) units;
- (NSString*) decayCorrection;
- (void) setDecayCorrection : (NSString*) s;
- (void) checkSUV;
- (BOOL) hasSUV;
- (BOOL) displaySUVValue;
- (void) setDisplaySUVValue : (BOOL) v;
- (void) copySUVfrom: (DCMPix*) from;
- (NSString *)setUnits: (NSString *) s;
- (float) getPixelValueX: (long) x Y:(long) y;

- (NSString *)srcFile;

- (NSMutableDictionary*) annotationsDictionary;

@end
