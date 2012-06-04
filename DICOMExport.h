/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>

@class DCMObject;
@class DCMExportPlugin;


#ifdef __cplusplus

#ifdef OSIRIX_VIEWER
#include "osconfig.h"
#include "dcfilefo.h"
#include "dcdeftag.h"
#include "ofstd.h"

#include "dctk.h"
#include "dcdebug.h"
#include "cmdlnarg.h"
#include "ofconapp.h"
#include "dcuid.h"       /* for dcmtk version name */
#else
typedef char* DcmFileFormat;
#endif

#else
typedef char* DcmFileFormat;
#endif

/** \brief Export image as DICOM  */
@interface DICOMExport : NSObject
{
		NSString			*dcmSourcePath;
		
		DCMObject			*dcmDst;
		DcmFileFormat		*dcmtkFileFormat;
		
		// Raw data support
		unsigned char		*data, *localData;
		long				width, height, spp, bps;
		BOOL				isSigned, modalityAsSource, rotateRawDataBy90degrees;
		int					offset;
		
		// NSImage support
		NSImage				*image;
		NSBitmapImageRep	*imageRepresentation;
		unsigned char		*imageData;
		BOOL				freeImageData;
		
		int					exportInstanceNumber, exportSeriesNumber;
		NSString			*exportSeriesUID;
		NSString			*exportSeriesDescription;
		
		long				ww, wl;
		float				spacingX, spacingY, slope;
		float				sliceThickness;
		float				sliceInterval;
		float				orientation[ 6];
		float				position[ 3];
		float				slicePosition;
    
        NSMutableDictionary *metaDataDict;
}
@property( readonly) NSMutableDictionary *metaDataDict;
@property BOOL rotateRawDataBy90degrees;

// Is this DCM file based on another DCM file?
- (void) setSourceFile:(NSString*) isource;

// Set Pixel Data from a raw source
- (long) setPixelData:		(unsigned char*) idata
		samplesPerPixel:	(int) ispp
		bitsPerSample:		(int) ibps
		width:				(long) iwidth
		height:				(long) iheight;

- (long) setPixelData:		(unsigned char*) deprecated
		samplePerPixel:		(long) deprecated
		bitsPerPixel:		(long) deprecated // This is INCORRECT - backward compatibility
		width:				(long) deprecated
		height:				(long) deprecated __deprecated;

- (void) setSigned: (BOOL) s;
- (void) setOffset: (int) o;

// Set Pixel Data from a NSImage
- (long) setPixelNSImage:	(NSImage*) iimage;

// Write the image data
- (NSString*) writeDCMFile: (NSString*) dstPath;
- (NSString*) writeDCMFile: (NSString*) dstPath withExportDCM:(DCMExportPlugin*) dcmExport;
- (void) setModalityAsSource: (BOOL) v;
- (NSString*) seriesDescription;
- (void) setSeriesDescription: (NSString*) desc;
- (void) setSeriesNumber: (long) no;
- (void) setDefaultWWWL: (long) ww :(long) wl;
- (void) setSlope: (float) s;
- (void) setPixelSpacing: (float) x :(float) y;
- (void) setSliceThickness: (double) t;
- (void) setOrientation: (float*) o;
- (void) setPosition: (float*) p;
- (void) setSlicePosition: (float) p;
@end
