//
//  DCMCStoreRequest.m
//  OsiriX
//
//  Created by Lance Pysher on 12/20/04.

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

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMCStoreRequest.h"
#import "DCM.h"


@implementation DCMCStoreRequest

+ (id)storeRequestWithAffectedSOPClassUID:(NSString *)classUID  affectedSOPInstanceUID:(NSString *)instanceUID{
	return [[[DCMCStoreRequest alloc] initWithAffectedSOPClassUID:(NSString *)classUID  affectedSOPInstanceUID:(NSString *)instanceUID] autorelease];
}

+ (id)storeRequestWithObject:(DCMObject *)aObject{
	return [[[DCMCStoreRequest alloc] initWithObject:aObject] autorelease];
}

- (id)initWithObject:(DCMObject *)aObject{
	if (self = [super init]) {
		dcmObject = [aObject retain];
		groupLength = [[dcmObject attributeValueWithName:@"CommandGroupLength"] intValue];
		affectedSOPClassUID = [[dcmObject attributeValueWithName:@"AffectedSOPClassUID"] retain];
		commandField = [[dcmObject attributeValueWithName:@"CommandField"] intValue];
		messageID = [[dcmObject attributeValueWithName:@"MessageID"] intValue];
		datasetType =  [[dcmObject attributeValueWithName:@"DataSetType"] intValue];
		priority = [[dcmObject attributeValueWithName:@"Priority"] intValue];
		affectedSOPInstanceUID =  [[dcmObject attributeValueWithName:@"AffectedSOPInstanceUID"] retain];
		
	}
	return self;
		
}
- (id)initWithAffectedSOPClassUID:(NSString *)classUID  affectedSOPInstanceUID:(NSString *)instanceUID{
	if (self = [super init]){
		affectedSOPClassUID = [classUID retain];
		affectedSOPInstanceUID = [instanceUID retain];
		//NSLog(@"Init DCMCStoreRequest affectedSOPClassUID:%@  SOPInstanceUID:%@", classUID, instanceUID);
		commandField = 0x0001;	// C-STORE-RQ
		messageID = 0x0001;
		priority = 0x0000;	// MEDIUM
		datasetType = 0x0001;	// anything other than 0x0101 (none), since a C-STORE-RQ always has a data set

		//sopClass attr
		DCMAttributeTag *sopClassTag = [DCMAttributeTag tagWithName:@"AffectedSOPClassUID"];
		DCMAttribute *sopClassAttr = [DCMAttribute attributeWithAttributeTag:sopClassTag  vr:@"UI"  values:[NSMutableArray arrayWithObject:classUID]];
		//command field attr
		DCMAttributeTag *commandFieldTag = [DCMAttributeTag tagWithName:@"CommandField"];
		DCMAttribute *commandFieldAttr = [DCMAttribute attributeWithAttributeTag:commandFieldTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:commandField]]];
		//messsage ID attr
		DCMAttributeTag *messageIDTag = [DCMAttributeTag tagWithName:@"MessageID"];
		DCMAttribute *messageIDAttr = [DCMAttribute attributeWithAttributeTag:messageIDTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:messageID]]];
		//dataset type attr
		DCMAttributeTag *datasetTypeTag = [DCMAttributeTag tagWithName:@"DataSetType"];
		DCMAttribute *datasetTypeAttr = [DCMAttribute attributeWithAttributeTag:datasetTypeTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:datasetType]]];
		//priority
		DCMAttributeTag *priorityTag = [DCMAttributeTag tagWithName:@"Priority"];
		DCMAttribute *priorityAttr = [DCMAttribute attributeWithAttributeTag:priorityTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:priority]]];
		//instance UID tag
		DCMAttributeTag *sopInstanceTag = [DCMAttributeTag tagWithName:@"AffectedSOPInstanceUID"];
		DCMAttribute *sopInstanceAttr = [DCMAttribute attributeWithAttributeTag:sopInstanceTag  vr:@"UI"  values:[NSMutableArray arrayWithObject:instanceUID]];
		
		
		dcmObject = [[DCMObject dcmObject] retain];
		[dcmObject setAttribute:sopClassAttr];
		[dcmObject setAttribute:commandFieldAttr];
		[dcmObject setAttribute:messageIDAttr];
		[dcmObject setAttribute:datasetTypeAttr];
		[dcmObject setAttribute:priorityAttr];
		[dcmObject setAttribute:sopInstanceAttr];

		groupLength = [[self data] length];
		//length attr
		DCMAttributeTag *groupLengthTag = [DCMAttributeTag tagWithName:@"CommandGroupLength"];
		DCMAttribute *groupLengthAttr = [DCMAttribute attributeWithAttributeTag:groupLengthTag  vr:@"UL"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:groupLength]]];
		[dcmObject setAttribute:groupLengthAttr];
	}
	//NSLog(@"return CStoreRequest");
	return self;
}

- (int)priority{
	return priority;
}

	

@end

