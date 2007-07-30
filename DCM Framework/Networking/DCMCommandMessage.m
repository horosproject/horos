//
//  DCMCommandMessage.m
//  OsiriX
//
//  Created by Lance Pysher on 12/13/04.
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

#import "DCMCommandMessage.h"
#import "DCM.h"

@implementation DCMCommandMessage

- (DCMObject *)dcmObject{
	return dcmObject;
}
- (NSData *)data{
	DCMDataContainer *container = [DCMDataContainer dataContainer];
	if ([dcmObject writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]
			quality:DCMLosslessQuality 
			asDICOM3:NO
			strippingGroupLengthLength:NO])
		return [container dicomData];
	return nil;
}

- (void)dealloc{
	[dcmObject release];
	[affectedSOPClassUID release];
	[affectedSOPInstanceUID release];
	[requestedSOPClassUID release];
	[requestedSOPInstanceUID release];
	[super dealloc];
}

- (int)groupLength{
	return groupLength;
}

- (NSString *)affectedSOPClassUID{
	return affectedSOPClassUID;
}

- (NSString *)affectedSOPInstanceUID{
	return affectedSOPInstanceUID;
}

- (NSString *)requestedSOPClassUID{
	return requestedSOPClassUID;
}
- (NSString *)requestedSOPInstanceUID{
	return requestedSOPInstanceUID;
}

- (int)commandField{
	return commandField;
}

- (int)messageID{
	return messageID;
}

- (int)messageIDBeingRespondedTo{
	return messageIDBeingRespondedTo;
}

- (int)status{
	return status;
}

- (unsigned short )priority{
	return priority;
}

- (NSString *)description{
	return [NSString stringWithFormat:@"Command Message:%@", [dcmObject description]];
}

- (id)initWithObject:(DCMObject *)object{
	if (self = [super init]) {
		dcmObject = [object retain];
		commandField = [[dcmObject attributeValueWithName:@"CommandField"] shortValue];
		if ([dcmObject attributeValueWithName:@"MessageIDBeingRespondedTo"] )
			messageID = [[dcmObject attributeValueWithName:@"MessageIDBeingRespondedTo"] shortValue];
		else
			messageID = [[dcmObject attributeValueWithName:@"MessageID"] shortValue];
		affectedSOPClassUID = [[dcmObject attributeValueWithName:@"AffectedSOPClassUID"] retain];
		affectedSOPInstanceUID = [[dcmObject attributeValueWithName:@"AffectedSOPInstanceUID"] retain];
		requestedSOPClassUID = [[dcmObject attributeValueWithName:@"RequestedSOPClassUID"] retain];
		requestedSOPInstanceUID = [[dcmObject attributeValueWithName:@"RequestedSOPInstanceUID"] retain];
		status = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Status"]] value] intValue];
		priority = [[dcmObject attributeValueWithName:@"Priority"] shortValue];
	}
	return self;
}

@end
