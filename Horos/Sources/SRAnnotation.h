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

#ifdef __cplusplus
#include "dsrdoc.h"
#else
typedef char DSRDocument;
#endif

#import "ROI.h"
#import "DicomImage.h"

@interface SRAnnotation : NSObject
{
	DSRDocument			*document;
	DicomImage          *image;
	BOOL				_newSR;
	NSString			*_seriesInstanceUID, *_DICOMSRDescription, *_DICOMSeriesNumber, *_reportURL;
	NSData				*_dataEncapsulated;
	NSDate				*_contentDate;
}

/** Extracts ROI as NSData from a DICOM SR
 * @param path File path
 */
+ (NSData *) roiFromDICOM:(NSString *)path;

/** Creates a DICOM SR from an array of ROIs
 * @param rois Array of ROI to archive
 * @param path Path to file 
 * @param image the image related to the ROI array
 */
+ (NSString*) archiveROIsAsDICOM:(NSArray *)rois toPath:(NSString *)path  forImage:(id)image;


+ (NSString*) getImageRefSOPInstanceUID:(NSString*) path;
+ (NSString*) getReportFilenameFromSR:(NSString*) path;

- (id) initWithROIs:(NSArray *)ROIs  path:(NSString *)path forImage:(NSManagedObject*) im;
- (id) initWithContentsOfFile:(NSString *)path;
- (id) initWithDictionary:(NSDictionary *) dict path:(NSString *) path forImage: (DicomImage*) im;
- (id) initWithWindowsState:(NSData *) dict path:(NSString *) path forImage: (DicomImage*) im;
- (id) initWithFileReport:(NSString *) file path:(NSString *) path forImage: (DicomImage*) im contentDate: (NSDate*) d;
- (id) initWithURLReport:(NSString *) s path:(NSString *) path forImage: (DicomImage*) im;
- (void) addROIs:(NSArray *)someROIs;
- (NSArray *) ROIs;
- (BOOL) writeToFileAtPath:(NSString *)path;
- (NSString *) seriesInstanceUID;
- (void) setSeriesInstanceUID: (NSString *)seriesInstanceUID;
- (NSString *) sopInstanceUID;
- (NSString *) sopClassUID;
- (NSString *) seriesDescription;
- (NSString *) seriesNumber;
- (NSData*) dataEncapsulated;
- (NSString*) reportURL;
- (NSDictionary*) annotations;
@end
