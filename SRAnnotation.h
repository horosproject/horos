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

#ifdef __cplusplus
#include "dsrdoc.h"
#else
typedef char DSRDocument;
#endif

#import "ROI.h"

@interface SRAnnotation : NSObject
{
	DSRDocument			*document;
	id					image;
	BOOL				_newSR;
	NSString			*_seriesInstanceUID, *_DICOMSRDescription, *_DICOMSeriesNumber, *_reportURL;
	NSData				*_dataEncapsulated;
}

+ (NSString*) getImageRefSOPInstanceUID:(NSString*) path;
+ (NSString*) getReportFilenameFromSR:(NSString*) path;

- (id) initWithROIs:(NSArray *)ROIs  path:(NSString *)path forImage:(NSManagedObject*) im;
- (id) initWithContentsOfFile:(NSString *)path;
- (id) initWithDictionary:(NSDictionary *) dict path:(NSString *) path forImage: (NSManagedObject*) im;
- (id) initWithFileReport:(NSString *) file path:(NSString *) path forImage: (NSManagedObject*) im;
- (id) initWithURLReport:(NSString *) s path:(NSString *) path forImage: (NSManagedObject*) im;
- (void) addROIs:(NSArray *)someROIs;
- (NSArray *) ROIs;
- (BOOL) writeToFileAtPath:(NSString *)path;
- (void) saveAsHTML;
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
