//
//  DCMTKSeriesQueryNode.mm
//  OsiriX
//
//  Created by Lance Pysher on 4/4/06.

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
#import "DCMTKSeriesQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
#import "DCMTKImageQueryNode.h"
#import "DICOMToNSString.h"

#undef verify
#include "dcdeftag.h"


@implementation DCMTKSeriesQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKSeriesQueryNode alloc] initWithDataset:(DcmDataset *)dataset
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
		_studyInstanceUID = nil;
		const char *string = nil;
		
		if (dataset ->findAndGetString(DCM_SpecificCharacterSet, string).good())
			_specificCharacterSet = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];

		if (dataset ->findAndGetString(DCM_SeriesInstanceUID, string).good()) 
			_uid = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			
		if (dataset ->findAndGetString(DCM_StudyInstanceUID, string).good()) 
			_studyInstanceUID = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];	
			
		if (dataset ->findAndGetString(DCM_SeriesDescription, string).good()) 
			_theDescription = [[NSString alloc] initWithCString:string  DICOMEncoding:_specificCharacterSet];
			
		if (dataset ->findAndGetString(DCM_SeriesNumber, string).good()) 
			_name = [[NSString alloc] initWithCString:string  DICOMEncoding:_specificCharacterSet];
			
			
		if (dataset ->findAndGetString(DCM_SeriesDate, string).good()) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_date = [[DCMCalendarDate dicomDate:dateString] retain];
			[dateString release];
		}
		
		if (dataset ->findAndGetString(DCM_SeriesTime, string).good()) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_time = [[DCMCalendarDate dicomTime:dateString] retain];
			[dateString release];
		}
		
		if (dataset ->findAndGetString(DCM_Modality, string).good())	
			_modality = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			
		if (dataset ->findAndGetString(DCM_NumberOfSeriesRelatedInstances, string).good())	
			_numberImages = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];

	}
	return self;
}

- (void)dealloc{
	[_studyInstanceUID release];
	[super dealloc];
}

- (DcmDataset *)queryPrototype{
	DcmDataset *dataset = new DcmDataset();
	dataset-> insertEmptyElement(DCM_InstanceCreationDate, OFTrue);
	dataset-> insertEmptyElement(DCM_InstanceCreationTime, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_SOPInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_InstanceNumber, OFTrue);
	dataset-> putAndInsertString(DCM_SeriesInstanceUID, [_uid UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_StudyInstanceUID, [_uid UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE", OFTrue);
	
	return dataset;
	
}

- (void)addChild:(DcmDataset *)dataset{
	if (!_children)
		_children = [[NSMutableArray alloc] init];
	[_children addObject:[DCMTKImageQueryNode queryNodeWithDataset:dataset
	callingAET:_callingAET  
			calledAET:_calledAET
			hostname:_hostname 
			port:_port 
			transferSyntax:_transferSyntax
			compression: _compression
			extraParameters:_extraParameters]];
}


@end
