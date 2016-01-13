/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/

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
	int		_bitsAllocated;
	BOOL	_isShort, _isSigned;
	float	_compression;
	int		_min;
	int		_max;
	DCMTransferSyntax *transferSyntax;
	BOOL	_isDecoded;
	NSMutableArray *_framesDecoded;
	DCMObject *_dcmObject;
	BOOL  _framesCreated;
	NSRecursiveLock *singleThread;
}
		
@property int rows;
@property int columns;
@property int numberOfFrames;
@property(retain) DCMTransferSyntax *transferSyntax;
@property int samplesPerPixel;
@property int bytesPerSample;
@property int pixelDepth;
@property BOOL isShort;
@property float compression;
@property BOOL isDecoded;

+ (void) setUse_kdu_IfAvailable:(int) b;

- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			transferSyntax:(DCMTransferSyntax *)ts
			dcmObject:(DCMObject *)dcmObject
			decodeData:(BOOL)decodeData;

- (void)deencapsulateData:(DCMDataContainer *)dicomData;

- (void)addFrame:(NSMutableData *)data;
- (void)replaceFrameAtIndex:(int)index withFrame:(NSMutableData *)data;

//Pixel decoding
- (void)decodeData;
- (BOOL)convertToTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality;
- (NSMutableData *)encodeJPEG2000:(NSMutableData *)data quality:(int)quality;
- (NSData *)convertDataFromLittleEndianToHost:(NSMutableData *)data;
- (NSData *)convertDataFromBigEndianToHost:(NSMutableData *)data;
- (void)convertLittleEndianToHost;
- (void)convertBigEndianToHost;
- (void)convertHostToLittleEndian;
- (void)convertHostToBigEndian;
- (NSData *)convertJPEG8ToHost:(NSData *)jpegData;
- (NSData *)convertJPEG2000ToHost:(NSData *)jpegData;
- (NSData *)convertRLEToHost:(NSData *)rleData;
- (NSData *)convertJPEGLSToHost:(NSData *)jpegLsData;
- (void)createOffsetTable;
- (void)interleavePlanes;
- (NSData *)interleavePlanesInData:(NSData *)data;
- (NSMutableData *)createFrameAtIndex:(int)index;
- (void)createFrames;
- (void)setLossyImageCompressionRatio:(NSMutableData *)data quality: (int) quality;
- (void)findMinAndMax:(NSMutableData *)data;
//- (void)decodeRescale;
//RGB data will be interleaved after being converted from Palette or YBR.
- (void)convertToRGBColorspace;
- (NSData *)convertDataToRGBColorSpace:(NSData *)data;
- (NSData *)convertPaletteToRGB:(NSData *)data;
- (NSData *) convertYBrToRGB:(NSData *)ybrData kind:(NSString *)theKind isPlanar:(BOOL)isPlanar;
- (NSData *)convertToFloat:(NSData *)data;
- (NSMutableData *)decodeFrameAtIndex:(int)index;
//- (NSImage *)imageAtIndex:(int)index ww:(float)ww  wl:(float)wl;

@end
