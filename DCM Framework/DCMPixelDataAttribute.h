//
//  DCMPixelDataAttribute.h
//  DCMSampleApp
//
//  Created by Lance Pysher on Fri Jun 18 2004.

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

// 7/7/2005 Fixed bug with planar configuration and YBR. LP

#import <Foundation/Foundation.h>
#import "DCMAttribute.h"

enum photometricmode{DCM_UNKNOWN_PHOTOMETRIC, DCM_MONOCHROME1,  DCM_MONOCHROME2, DCM_RGB, DCM_ARGB,  DCM_YBR_FULL_422, DCM_YBR_PARTIAL_422, DCM_YBR_FULL, DCM_YBR_RCT,  DCM_YBR_ICT, DCM_HSV, DCM_CMYK, DCM_PALETTE };



@class DCMTransferSyntax;
@class DCMObject;
@class NSImage;

@interface DCMPixelDataAttribute : DCMAttribute {
	int		_rows;
	int		_columns;
	int		_samplesPerPixel;
	int		_bytesPerSample;
	int		_numberOfFrames;
	int		_pixelDepth;
	BOOL	_isShort, _isSigned;
	float	_compression;
	int		_min;
	int		_max;
	DCMTransferSyntax *transferSyntax;
	BOOL	_isDecoded;
	DCMObject *_dcmObject;
	BOOL  _framesCreated;

}
		

			
- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			transferSyntax:(DCMTransferSyntax *)ts
			dcmObject:(DCMObject *)dcmObject
			decodeData:(BOOL)decodeData;

- (void)deencapsulateData:(DCMDataContainer *)dicomData;

- (void)setRows:(int)rows;
- (void)setColumns:(int)columns;
- (void)setNumberOfFrames:(int)frames;
- (void)setTransferSyntax:(DCMTransferSyntax *)ts;
- (void)setSamplesPerPixel:(int)spp;
- (void)setBytesPerSample:(int)bps;
- (void)setPixelDepth:(int)depth;
- (void)setIsShort:(BOOL)value;
- (void)setCompression:(float)compression;
- (void)setIsDecoded:(BOOL)value;


- (int)rows;
- (int)columns;
- (int)numberOfFrames;
- (DCMTransferSyntax *)transferSyntax;
- (int)samplesPerPixel;
- (int)bytesPerSample;
- (int)pixelDepth;
- (BOOL)isShort;
- (float)compression;
- (BOOL)isDecoded;



- (void)addFrame:(NSMutableData *)data;
- (void)replaceFrameAtIndex:(int)index withFrame:(NSMutableData *)data;


//Pixel decoding
- (void)decodeData;
- (BOOL)convertToTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality;
- (NSMutableData *)encodeJPEG2000:(NSMutableData *)data quality:(int)quality;
- (NSMutableData *)convertDataFromLittleEndianToHost:(NSMutableData *)data;
- (NSMutableData *)convertDataFromBigEndianToHost:(NSMutableData *)data;
- (void)convertLittleEndianToHost;
- (void)convertBigEndianToHost;
- (void)convertHostToLittleEndian;
- (void)convertHostToBigEndian;
- (NSMutableData *)convertJPEG8ToHost:(NSData *)jpegData;
- (NSMutableData *)convertJPEG2000ToHost:(NSData *)jpegData;
- (NSMutableData *)convertRLEToHost:(NSData *)rleData;
//- (void)decodeRescale:(NSMutableData *)data;
- (void)encodeRescale:(NSMutableData *)data WithRescaleIntercept:(int)offset;
- (void)encodeRescale:(NSMutableData *)data WithPixelDepth:(int)pixelDepth;
#if __ppc__
- (void)decodeRescaleAltivec:(NSMutableData *)data;
- (void)encodeRescaleAltivec:(NSMutableData *)data withPixelDepth:(int)pixelDepth;
#endif
- (void)decodeRescaleScalar: (NSMutableData *)data;
- (void)encodeRescaleScalar:(NSMutableData *)data withPixelDepth:(int)pixelDepth;
- (void)createOffsetTable;
- (void)interleavePlanes;
- (NSMutableData *)interleavePlanesInData:(NSMutableData *)data;
- (NSMutableData *)createFrameAtIndex:(int)index;
- (void)createFrames;
- (void)setLossyImageCompressionRatio:(NSMutableData *)data;
- (void)findMinAndMax:(NSMutableData *)data;
- (void)decodeRescale;
//RGB data will be interleaved after being converted from Palette or YBR.
- (void)convertToRGBColorspace;
- (NSMutableData *)convertDataToRGBColorSpace:(NSMutableData *)data;
- (NSMutableData *)convertPaletteToRGB:(NSMutableData *)data;
- (NSMutableData *) convertYBrToRGB:(NSData *)ybrData kind:(NSString *)theKind isPlanar:(BOOL)isPlanar;
- (NSMutableData *)convertToFloat:(NSMutableData *)data;
- (NSMutableData *)decodeFrameAtIndex:(int)index;
- (NSImage *)imageAtIndex:(int)index ww:(float)ww  wl:(float)wl;



@end
