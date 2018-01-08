/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import "DCMCalendarDate.h"
#import "DicomFile.h"

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

- (DcmDataset *)queryPrototype
{
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
    dataset-> insertEmptyElement(DCM_InstitutionName, OFTrue);
    dataset-> insertEmptyElement(DCM_ReferringPhysiciansName, OFTrue);
    dataset-> insertEmptyElement(DCM_PerformingPhysiciansName, OFTrue);
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CFINDBodyPartExaminedSupport"])
        dataset-> insertEmptyElement(DCM_BodyPartExamined, OFTrue);
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CFINDCommentsAndStatusSupport"])
    {
        dataset-> insertEmptyElement(DCM_StudyComments, OFTrue);
        dataset-> insertEmptyElement(DCM_InterpretationStatusID, OFTrue);
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
        dataset-> insertEmptyElement(DCM_ModalitiesInStudy, OFTrue);
    else
        dataset-> insertEmptyElement(DCM_Modality, OFTrue);
    
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "STUDY", OFTrue);
	
	return dataset;
}

- (void)addChild:(DcmDataset *)dataset
{
    @synchronized( _children)
	{
        if (!_children)
            _children = [[NSMutableArray alloc] init];
	}
    
	if( dataset == nil)
		return;
	
    @synchronized( _children)
	{
        if( [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"] > 0 && _children.count > [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"])
        {
            NSLog( @"----- C-Find maximumNumberOfCFindObjects reached: %d, %d", (int) _children.count, (int) [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"]);
        }
        else
        {
            DCMTKStudyQueryNode *newNode = [DCMTKStudyQueryNode queryNodeWithDataset:dataset
                                                                          callingAET:_callingAET
                                                                           calledAET:_calledAET
                                                                            hostname:_hostname
                                                                                port:_port
                                                                      transferSyntax:_transferSyntax
                                                                         compression: _compression
                                                                     extraParameters:_extraParameters];
            
            BOOL alreadyHere = NO;
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QRRemoveDuplicateEntries"])
            {
                //Is it already here?
                for( DCMTKStudyQueryNode* s in _children)
                {
                    if( [s.studyInstanceUID isEqualToString: newNode.studyInstanceUID] && [s.name isEqualToString: newNode.name] && [s.accessionNumber isEqualToString: newNode.accessionNumber] && [s.numberImages intValue] == [newNode.numberImages intValue] && [s.date isEqualToDate: newNode.date])
                        alreadyHere = YES;
                }
            }
            
            if( alreadyHere == NO)
                [_children addObject: newNode];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: @"realtimeCFindResults" object: self];
        }
    }
}
@end
