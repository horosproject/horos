//
//  DCMCEchoResponse.m
//  OsiriX
//
//  Created by Lance Pysher on 12/20/04.

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

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMCEchoResponse.h"
#import "DCM.h"


@implementation DCMCEchoResponse

+ (id)echoResponseWithObject:(DCMObject *)object{
	return [[[DCMCEchoResponse alloc] initWithObject:object] autorelease];
}

+ (id)echoResponseWithAffectedClassUID:(NSString *)uid  messageIDBeingRespondedTo:(int)messageIDBRT  status:(int)aStatus{
	return [[[DCMCEchoResponse alloc] initWithAffectedClassUID:(NSString *)uid  messageIDBeingRespondedTo:(int)messageIDBRT  status:(int)aStatus] autorelease];
}

- (id)initWithObject:(DCMObject *)aObject{
	if (self = [super init]) {
		dcmObject = [aObject retain];
		groupLength = [(NSNumber *)[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandGroupLength"]] intValue];
		affectedSOPClassUID = [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AffectedSOPClassUID"]] retain];
		commandField = [(NSNumber *)[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandField"]] intValue];
		messageIDBeingRespondedTo = [(NSNumber *)[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"MessageIDBeingRespondedTo"]] intValue];
		status = [(NSNumber *)[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Status"]] intValue];
	}
	return self;
}

- (id)initWithAffectedClassUID:(NSString *)uid  messageIDBeingRespondedTo:(int)messageIDBRT  status:(int)aStatus{
	if (self = [super init]){
		groupLength = 0;
		commandField = 0x8030;	// C-ECHO-RQ
		datasetType = 0x0101;	// none
		messageIDBeingRespondedTo = messageIDBRT;
		affectedSOPClassUID = [uid retain];
		status = aStatus;

		//sopClass attr
		DCMAttributeTag *sopClassTag = [DCMAttributeTag tagWithName:@"AffectedSOPClassUID"];
		DCMAttribute *sopClassAttr = [DCMAttribute attributeWithAttributeTag:sopClassTag  vr:@"UI"  values:[NSMutableArray arrayWithObject:uid]];
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
		DCMAttribute *statusAttr = [DCMAttribute attributeWithAttributeTag:statusTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:aStatus]]];
		
		
		dcmObject = [[DCMObject dcmObject] retain];
		[dcmObject setAttribute:sopClassAttr];
		[dcmObject setAttribute:commandFieldAttr];
		[dcmObject setAttribute:messageIDAttr];
		[dcmObject setAttribute:datasetTypeAttr];
		[dcmObject setAttribute:statusAttr];
		
		groupLength = [[self data] length];
		//length attr
		DCMAttributeTag *groupLengthTag = [DCMAttributeTag tagWithName:@"CommandGroupLength"];
		DCMAttribute *groupLengthAttr = [DCMAttribute attributeWithAttributeTag:groupLengthTag  vr:@"UL"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:groupLength]]];
		[dcmObject setAttribute:groupLengthAttr];


	}
	return self;
}
/*
- (void)dealloc{
	[affectedSOPClassUID release];
	[super dealloc];
}
*/
- (NSString *)description{
	return [NSString stringWithFormat:@"CEcho ResponseCommand Message:%@", [dcmObject description]];
}




@end
