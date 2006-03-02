//
//  DCMRootQueryNode.m
//  OsiriX
//

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
//

#import "DCMRootQueryNode.h"
#import "DCM.h"
#import "DCMNetworking.h"

@implementation DCMRootQueryNode

+ (id)queryNodeWithObject:(DCMObject *)object{
	return [[[DCMRootQueryNode alloc] initWithObject:(DCMObject *)object] autorelease];
}

- (DCMObject *)queryPrototype{
	//root will search for studies
	DCMObject *findObject = [DCMObject dcmObject];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyDescription"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyDate"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyTime"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyNumber"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"NumberofStudyRelatedInstances"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"ModalitiesinStudy"];
	[findObject setAttributeValues:[NSMutableArray arrayWithObject:@"STUDY"] forName:@"Query/RetrieveLevel"];
	//NSLog(@"query prototype: %@", [findObject description]);
	return findObject;
}

- (void)addChild:(id)child{
	if (!children)
		children = [[NSMutableArray array] retain];
	[children addObject:[DCMStudyQueryNode queryNodeWithObject:child]];;
}


	

@end
