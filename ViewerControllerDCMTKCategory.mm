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
- (void)archiveROIsAsDICOM:(NSArray *)rois toPath:(NSString *)path{
	//SRAnnotation *sr = [[SRAnnotation alloc] init];
	SRAnnotation *sr = [[SRAnnotation alloc] initWithROIs:rois path:path];
	//[sr addROIs:rois];
	[sr writeToFileAtPath:path];
	[sr release];
}
@end
