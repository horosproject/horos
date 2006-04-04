//
//  DCMTKRootQueryNode.mm
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

#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>

#include "dcdeftag.h"


@implementation DCMTKRootQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset{
	return [[[DCMTKRootQueryNode alloc] initWithDataset:(DcmDataset *)dataset] autorelease];
}

- (DcmDataset *)queryPrototype{
	DcmDataset *dataset = new DcmDataset();
	dataset-> insertEmptyElement(DCM_PatientsName, OFTrue);
	dataset-> insertEmptyElement(DCM_PatientID, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyDescription, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyDate, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyTime, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyID, OFTrue);
	dataset-> insertEmptyElement(DCM_NumberOfStudyRelatedInstances, OFTrue);
	dataset-> insertEmptyElement(DCM_ModalitiesInStudy, OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "STUDY", OFTrue);
	
	return dataset;
	
}

- (void)addChild:(DcmDataset *)dataset{
	if (!_children)
		_children = [[NSMutableArray alloc] init];
	[_children addObject:[DCMTKStudyQueryNode queryNodeWithDataset:dataset]];
}



@end
