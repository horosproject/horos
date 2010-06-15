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

#import "ROISRConverter.h"
#import "SRAnnotation.h"
#import "DicomStudy.h"
#import "DicomImage.h"
#import "browserController.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"
#include "dsrdoc.h"

@implementation ROISRConverter

+ (NSData *)roiFromDICOM:(NSString *)path
{
	NSData *archiveData = nil;
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([path UTF8String]);
	if( status != EC_Normal) return nil;
	
	OFString name;
	const Uint8 *buffer = nil;
	unsigned int length;
	
	if (fileformat.getDataset()->findAndGetUint8Array(DCM_EncapsulatedDocument, buffer, &length, OFFalse).good())	//DCM_EncapsulatedDocument
	{
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	else if (fileformat.getDataset()->findAndGetUint8Array(DCM_OsirixROI, buffer, &length, OFFalse).good())	//DCM_EncapsulatedDocument
	{
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	
	return archiveData;
}

//All the ROIs for an image are archived as an NSArray.  We will need to extract all the necessary ROI info to create the basic SR before adding archived data. 
+ (NSString*) archiveROIsAsDICOM: (NSArray *) rois toPath: (NSString *) path forImage: (id) image
{
	SRAnnotation *sr = [[[SRAnnotation alloc] initWithROIs:rois path:path forImage:image] autorelease];
	id study = [image valueForKeyPath:@"series.study"];
	
	NSManagedObject *roiSRSeries = [study roiSRSeries];
	
	if( roiSRSeries == nil)
	{
		[sr writeToFileAtPath: path];
		
		[[BrowserController currentBrowser] addFilesToDatabase: [NSArray arrayWithObject: path]];
		roiSRSeries = [study roiSRSeries];
		if( roiSRSeries == nil)
			NSLog( @"********** roiSRSeries == nil -- archiveROIsAsDICOM");
		
		[sr setSeriesInstanceUID: [roiSRSeries valueForKey:@"seriesDICOMUID"]];
		[sr writeToFileAtPath: path];
		
		return nil;
	}
	
	NSString *seriesInstanceUID = [roiSRSeries valueForKey:@"seriesDICOMUID"];
	
	[sr setSeriesInstanceUID: seriesInstanceUID];
	[sr writeToFileAtPath: path];
	
	BOOL AddIt = NO;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	@try 
	{
		if( roiSRSeries)
		{
			//Check to see if there is already this ROI-image
			NSString		*sopInstanceUID = [sr sopInstanceUID];
			NSArray			*srs = [(NSSet *)[roiSRSeries valueForKey:@"images"] allObjects];
			NSPredicate		*predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: sopInstanceUID]] customSelector: @selector( isEqualToSopInstanceUID:)];
			NSPredicate		*notNilPredicate = [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"];
			NSArray			*found = [[srs filteredArrayUsingPredicate: notNilPredicate] filteredArrayUsingPredicate: predicate];
			
			if ([found count] < 1)
				AddIt = YES;
		}
		else NSLog( @"********** roiSRSeries == nil -- archiveROIsAsDICOM");
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	if( AddIt)
		return path;
		
	return nil;
}
@end
