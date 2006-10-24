//
//  ViewerControllerDCMTK Category.mm
//  OsiriX
//
//  Created by Lance Pysher on 10/18/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ViewerControllerDCMTKCategory.h"
#import "SRAnnotation.h"
#import "DicomStudy.h"
#import "browserController.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

#include "dsrdoc.h"


@implementation ViewerController (ViewerControllerDCMTKCategory)


- (NSData *)roiFromDICOM:(NSString *)path
{
	NSData *archiveData = nil;
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([path UTF8String]);
	if( status != EC_Normal) return 0L;
	
	OFString name;
	const Uint8 *buffer;
	unsigned long length;
	
	if (fileformat.getDataset()->findAndGetUint8Array(DCM_OsirixROI, buffer, &length, OFFalse).good())
	{
		NSLog(@"Unarchive from SR");
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	
	return archiveData;
}


//All the ROIs for an image are archived as an NSArray.  We will need to extract all the necessary ROI info to create the basic SR before adding archived data. 
- (void)archiveROIsAsDICOM:(NSArray *)rois toPath:(NSString *)path  forImage:(id)image{
	//BrowserController *browser = [BrowserController currentBrowser];
	//NSManagedObjectModel *managedObjectModel = [browser managedObjectModel];
	//NSManagedObjectContext *context = [browser managedObjectContext];
	
	SRAnnotation *sr = [[SRAnnotation alloc] initWithROIs:rois path:path];
	
	/* We could create an ROI coreData relationship if we wanted to as use presentationStateInstanceUID for the ROI path. 
		And save presentationSeriesInstanceUID, but I won't right now
		Right now we will just get the Study for the imager and then the roiSRSeries relationship
	*/
	
	/*
	id study = [image valueForKeyPath:@"series.study"];
	NSArray *roiSRSeries = [study roiSRSeries];
	id series = nil;
	//check to see if there is already a roi Series. Use SeriesInstanceUID if there is.
	if ([roiSRSeries count] > 0) {
		series = [roiSRSeries objectAtIndex:0];
		NSString *seriesInstanceUID = [series valueForKey:@"seriesDICOMUID"];
		[sr setSeriesInstanceUID:seriesInstanceUID];
	}
	//create new Series Object
	else {
		series = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext:context];
		[series setValue:study forKey:@"study"];
		[series setValue:[sr seriesInstanceUID] forKey:@"seriesDICOMUID"];
	}
	//See if the SR is in the series. Add it if necessary
	NSArray *srs = [(NSSet *)[series valueForKey:@"images"] allObjects];
	NSString *sopInstanceUID = [sr sopInstanceUID];
	//Search for object with this UID
	// empty for now
	*/
	
	[sr writeToFileAtPath:path];
	[sr release];
}
@end
