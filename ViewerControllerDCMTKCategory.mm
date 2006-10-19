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

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

#include "dsrdoc.h"


@implementation ViewerController (ViewerControllerDCMTKCategory)


- (NSData *)roiFromDICOM:(NSString *)path{
	NSData *archiveData = nil;
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([path UTF8String]);
	OFString name;
	const Uint8 *buffer;
	unsigned long length;
	if (fileformat.getDataset()->findAndGetUint8Array(DCM_OsirixROI, buffer, &length, OFFalse).good()){
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	/*
	findAndGetUint8Array	( DCM_OsirixROI,
								const Uint8 *& 	value,
								unsigned long * 	count = NULL,
								const OFBool 	searchIntoSub = OFFalse
*/
	return archiveData;
}



@end
