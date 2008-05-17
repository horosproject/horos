//
//  DCMStudyQueryNode.m
//  OsiriX
//

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
//

#import "DCMStudyQueryNode.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMStudyQueryNode

+ (id)queryNodeWithObject:(DCMObject *)object{
	return [[[DCMStudyQueryNode alloc] initWithObject:(DCMObject *)object] autorelease];
}


- (DCMObject *)queryPrototype{
	//patient will search for series
	DCMObject *findObject = [DCMObject dcmObject];

	[findObject setAttributeValues:[NSMutableArray array] forName:@"SeriesDescription"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"SeriesDate"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"SeriesTime"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"SeriesInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"SeriesNumber"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"NumberofSeriesRelatedInstances"];
	
	[findObject setAttributeValues:[NSMutableArray array] forName:@"NumberofStudyRelatedInstances"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"ModalitiesinStudy"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"Modality"];
	
	// this will be be link to our UID
	[findObject setAttributeValues:[NSMutableArray arrayWithObject:[dcmObject attributeValueWithName:@"StudyInstanceUID"]] forName:@"StudyInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray arrayWithObject:@"SERIES"] forName:@"Query/RetrieveLevel"];
	return findObject;
}

- (void)addChild:(id)child{
	if (!children)
		children = [[NSMutableArray array] retain];
	[children addObject:[DCMSeriesQueryNode queryNodeWithObject:child]];
}

- (NSString *)uid{
	return [dcmObject attributeValueWithName:@"StudyInstanceUID"];
}
- (NSString *)theDescription{
	return [dcmObject attributeValueWithName:@"StudyDescription"];
}
- (NSString *)name{
	return [dcmObject attributeValueWithName:@"PatientsName"];
}

- (NSString *)patientID{
	return [dcmObject attributeValueWithName:@"PatientID"];
}
- (DCMCalendarDate *)date{
	return [dcmObject attributeValueWithName:@"StudyDate"];
}
- (DCMCalendarDate *)time{
	return [dcmObject attributeValueWithName:@"StudyTime"];
}
- (NSString *)modality{
	if ([dcmObject attributeValueWithName:@"ModalitiesinStudy"])
		return [dcmObject attributeValueWithName:@"ModalitiesinStudy"];
		
	return [dcmObject attributeValueWithName:@"Modality"];
}

- (NSNumber *)numberImages
{
	return [NSNumber numberWithInt:[[dcmObject attributeValueWithName:@"NumberofStudyRelatedInstances"] intValue]];	//NumberOfSeriesRelatedInstances
}

- (void)move:(NSDictionary *)parameters{
	NS_DURING
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
		[params setObject:[NSNumber numberWithInt:0] forKey:@"debugLevel"];
		if (![params objectForKey:@"moveDestination"])
			[params setObject:[params objectForKey:@"callingAET"]  forKey:@"moveDestination"];
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];			//ExplicitVRLittleEndianTransferSyntax
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelMove] forKey:@"affectedSOPClassUID"];
		[params setObject:[NSNumber numberWithInt:1000000] forKey:@"timeout"];
		
		DCMObject *moveObject = [DCMObject dcmObject];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[self uid]] forName:@"StudyInstanceUID"];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:@"STUDY"] forName:@"Query/RetrieveLevel"];
		
		[params setObject:moveObject forKey:@"moveObject"];
		//NSLog(@"move params; %@", [params description]);
		[DCMMoveSCU moveWithParameters:params];
	NS_HANDLER
		NSLog(@"Exception performing move: %@", [localException name]);
	NS_ENDHANDLER
}

@end
