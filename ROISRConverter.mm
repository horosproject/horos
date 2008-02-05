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

#import "ROISRConverter.h"
#import "SRAnnotation.h"
#import "DicomStudy.h"
#import "browserController.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"
#include "dsrdoc.h"

extern NSString* sopInstanceUIDDecode( unsigned char *r);
extern void* sopInstanceUIDEncode( NSString *sopuid);

@implementation ROISRConverter

+ (NSData *)roiFromDICOM:(NSString *)path
{
	NSData *archiveData = nil;
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([path UTF8String]);
	if( status != EC_Normal) return 0L;
	
	OFString name;
	const Uint8 *buffer = 0L;
	unsigned int length;
	
	if (fileformat.getDataset()->findAndGetUint8Array(DCM_EncapsulatedDocument, buffer, &length, OFFalse).good())	//DCM_EncapsulatedDocument   //DCM_OsirixROI
	{
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	else if (fileformat.getDataset()->findAndGetUint8Array(DCM_OsirixROI, buffer, &length, OFFalse).good())	//DCM_EncapsulatedDocument   //DCM_OsirixROI
	{
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	
	return archiveData;
}

//All the ROIs for an image are archived as an NSArray.  We will need to extract all the necessary ROI info to create the basic SR before adding archived data. 
+ (NSString*) archiveROIsAsDICOM:(NSArray *)rois toPath:(NSString *)path  forImage:(id)image
{
	SRAnnotation *sr = [[SRAnnotation alloc] initWithROIs:rois path:path forImage:image];
	id study = [image valueForKeyPath:@"series.study"];
	
	NSManagedObject *roiSRSeries = [study roiSRSeries];
	
	NSString	*seriesInstanceUID = [roiSRSeries valueForKey:@"seriesDICOMUID"];
	
	[sr setSeriesInstanceUID: seriesInstanceUID];
	[sr writeToFileAtPath:path];
	
	BOOL AddIt = NO;
	
	//Check to see if there is already a roi Series.
	if( roiSRSeries)
	{
		//Check to see if there is already this ROI-image
		NSString		*sopInstanceUID = [sr sopInstanceUID];
		
		
		
		NSArray			*srs = [(NSSet *)[roiSRSeries valueForKey:@"images"] allObjects];
		NSPredicate		*predicate = [NSPredicate predicateWithFormat:@"sopInstanceUID == %@", sopInstanceUID];
		NSArray			*found = [srs filteredArrayUsingPredicate:predicate];
		
		if ([found count] < 1)
			AddIt = YES;
	}
	else AddIt = YES;
	
	[sr release];
	
	if( seriesInstanceUID == 0L)	//Add it NOW to the DB! We need the seriesInstanceUID for the others
	{
		[[BrowserController currentBrowser] addFilesToDatabase: [NSArray arrayWithObject: path]];
	}
	else if( AddIt) return path;
	
	return 0L;
}
@end
