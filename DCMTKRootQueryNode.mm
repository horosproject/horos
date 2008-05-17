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

#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>

#include "dcdeftag.h"


@implementation DCMTKRootQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
						callingAET:(NSString *)myAET  
						calledAET:(NSString *)theirAET  
						hostname:(NSString *)hostname 
						port:(int)port 
						transferSyntax:(int)transferSyntax
						compression: (float)compression
									extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKRootQueryNode alloc] initWithDataset:(DcmDataset *)dataset
										callingAET:(NSString *)myAET  
										calledAET:(NSString *)theirAET  
										hostname:(NSString *)hostname 
										port:(int)port 
										transferSyntax:(int)transferSyntax
										compression: (float)compression
										extraParameters:(NSDictionary *)extraParameters] autorelease];
}

- (DcmDataset *)queryPrototype{
	DcmDataset *dataset = new DcmDataset();
	dataset-> insertEmptyElement(DCM_PatientsName, OFTrue);
	dataset-> insertEmptyElement(DCM_PatientID, OFTrue);
	dataset-> insertEmptyElement(DCM_AccessionNumber, OFTrue);
	dataset-> insertEmptyElement(DCM_PatientsBirthDate, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyDescription, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyDate, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyTime, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyID, OFTrue);
	dataset-> insertEmptyElement(DCM_NumberOfStudyRelatedInstances, OFTrue);
	dataset-> insertEmptyElement(DCM_ModalitiesInStudy, OFTrue);
	dataset-> insertEmptyElement(DCM_Modality, OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "STUDY", OFTrue);
	
	return dataset;
	
}

- (void)addChild:(DcmDataset *)dataset{
	if (!_children)
		_children = [[NSMutableArray alloc] init];
	[_children addObject:[DCMTKStudyQueryNode queryNodeWithDataset:dataset
			callingAET:_callingAET  
			calledAET:_calledAET
			hostname:_hostname 
			port:_port 
			transferSyntax:_transferSyntax
			compression: _compression
			extraParameters:_extraParameters]];
}



@end
