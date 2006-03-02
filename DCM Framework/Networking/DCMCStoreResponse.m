//
//  DCMCStoreResponse.m
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

#import "DCMCStoreResponse.h"
#import "DCM.h"


@implementation DCMCStoreResponse

+ (id)cStoreResponseWithObject:(DCMObject *)aObject{
	return [[[ DCMCStoreResponse alloc] initWithObject:aObject] autorelease];
}

+ (id)cStoreResponseWithAffectedSOPClassUID:(NSString *)classUID  affectedSOPInstanceUID:(NSString *)instanceUID messageIDBeingRespondedTo:(int)messageIDBRT status:(unsigned short)aStatus{
	return [[[ DCMCStoreResponse alloc] initWithAffectedSOPClassUID:(NSString *)classUID  affectedSOPInstanceUID:(NSString *)instanceUID messageIDBeingRespondedTo:(int)messageIDBRT status:(int)aStatus] autorelease];
}

- (id)initWithObject:(DCMObject *)aObject{
	if (self = [super init]) {
		dcmObject = [aObject retain];
		groupLength = [(NSNumber *)[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandGroupLength"]] intValue];
		affectedSOPClassUID = [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AffectedSOPClassUID"]] retain];
		commandField = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandField"]] value] intValue];
		messageIDBeingRespondedTo = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"MessageIDBeingRespondedTo"]]  value] intValue];
		status = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Status"]] value] intValue];
		affectedSOPInstanceUID = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AffectedSOPInstanceUID"]]  value] retain];
	}
	return self;
}

- (id)initWithAffectedSOPClassUID:(NSString *)classUID  affectedSOPInstanceUID:(NSString *)instanceUID messageIDBeingRespondedTo:(int)messageIDBRT status:(unsigned short)aStatus{
	if (self = [super init]) {
		commandField = 0x8001;	// C-STORE-RSP
		datasetType = 0x0101;	// no data set
		affectedSOPClassUID = [classUID retain];
		affectedSOPInstanceUID = [instanceUID retain];
		messageIDBeingRespondedTo = messageIDBRT;
		status = aStatus;

		//sopClass attr
		DCMAttributeTag *sopClassTag = [DCMAttributeTag tagWithName:@"AffectedSOPClassUID"];
		DCMAttribute *sopClassAttr = [DCMAttribute attributeWithAttributeTag:sopClassTag  vr:@"UI"  values:[NSMutableArray arrayWithObject:affectedSOPClassUID]];
		//command field attr
		DCMAttributeTag *commandFieldTag = [DCMAttributeTag tagWithName:@"CommandField"];
		DCMAttribute *commandFieldAttr = [DCMAttribute attributeWithAttributeTag:commandFieldTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:commandField]]];
		//messsage ID attr
		DCMAttributeTag *messageIDTag = [DCMAttributeTag tagWithName:@"MessageIDBeingRespondedTo"];
		DCMAttribute *messageIDAttr = [DCMAttribute attributeWithAttributeTag:messageIDTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:messageIDBRT]]];
		//dataset type attr
		DCMAttributeTag *datasetTypeTag = [DCMAttributeTag tagWithName:@"DataSetType"];
		DCMAttribute *datasetTypeAttr = [DCMAttribute attributeWithAttributeTag:datasetTypeTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:datasetType]]];
		//status
		DCMAttributeTag *statusTag = [DCMAttributeTag tagWithName:@"Status"];
		DCMAttribute *statusAttr = [DCMAttribute attributeWithAttributeTag:statusTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:aStatus]]];
		//AffectedSOPInstanceUID
		DCMAttributeTag *sopInstanceTag = [DCMAttributeTag tagWithName:@"AffectedSOPInstanceUID"];
		DCMAttribute *sopInstanceAttr = [DCMAttribute attributeWithAttributeTag:sopInstanceTag  vr:@"UI"  values:[NSMutableArray arrayWithObject:instanceUID]];
		
		
		dcmObject = [[DCMObject dcmObject] retain];
		[dcmObject setAttribute:sopClassAttr];
		[dcmObject setAttribute:commandFieldAttr];
		[dcmObject setAttribute:messageIDAttr];
		[dcmObject setAttribute:datasetTypeAttr];
		[dcmObject setAttribute:statusAttr];
		[dcmObject setAttribute:sopInstanceAttr];

		groupLength = [[self data] length];
		//length attr
		DCMAttributeTag *groupLengthTag = [DCMAttributeTag tagWithName:@"CommandGroupLength"];
		DCMAttribute *groupLengthAttr = [DCMAttribute attributeWithAttributeTag:groupLengthTag  vr:@"UL"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:groupLength]]];
		[dcmObject setAttribute:groupLengthAttr];
	}
	return self;
}

- (NSString *)description{
	return [NSString stringWithFormat:@"CStore ResponseCommand Message:%@", [dcmObject description]];
}

@end
