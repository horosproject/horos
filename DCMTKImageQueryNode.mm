//
//  DCMTKImageQueryNode.mm
//  OsiriX
//
//  Created by Lance Pysher on 4/4/06.

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

#import "DCMTKImageQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
#import "DICOMToNSString.h"


#undef verify
#include "dcdeftag.h"


@implementation DCMTKImageQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKImageQueryNode alloc] initWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters] autorelease];
}

- (id)initWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters{
	if (self = [super initWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters]) {
		const char *string = nil;
				
		if (dataset ->findAndGetString(DCM_SpecificCharacterSet, string).good() && string != nil)
			_specificCharacterSet = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];

		if (dataset ->findAndGetString(DCM_SOPInstanceUID, string).good() && string != nil) 
			_uid = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];

			
		if (dataset ->findAndGetString(DCM_InstanceNumber, string).good() && string != nil) 
			_name = [[NSString alloc] initWithCString:string  DICOMEncoding:_specificCharacterSet];
			
			
		if (dataset ->findAndGetString(DCM_InstanceCreationDate, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_date = [[DCMCalendarDate dicomDate:dateString] retain];
			[dateString release];
		}
		
		if (dataset ->findAndGetString(DCM_InstanceCreationTime, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_time = [[DCMCalendarDate dicomTime:dateString] retain];
			[dateString release];
		}


	}
	return self;
}

- (DcmDataset *)moveDataset{
	DcmDataset *dataset = new DcmDataset();
	dataset-> putAndInsertString(DCM_SOPInstanceUID, [_uid UTF8String], OFTrue);
	//dataset-> putAndInsertString(DCM_StudyInstanceUID, [_studyInstanceUID UTF8String], OFTrue);
	//dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "SERIES", OFTrue);
	return dataset;
}




@end
