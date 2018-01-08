/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/



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
		BOOL				isSigned, modalityAsSource, rotateRawDataBy90degrees, triedToDecompress;
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
