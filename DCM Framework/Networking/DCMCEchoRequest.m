//
//  DCMCEchoRequest.m
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

#import "DCMCEchoRequest.h"
#import "DCM.h"
#import "DCMAbstractSyntaxUID.h"

@implementation DCMCEchoRequest

+ (id)CEchoRequest{
	return [[[DCMCEchoRequest alloc] init] autorelease];
}

- (id)init {
	if (self = [super init]){
		commandField = 0x0030;
		messageID = 0x0001;
		datasetType = 0x0101;
		affectedSOPClassUID = [[DCMAbstractSyntaxUID verificationClassUID] retain];

		//sopClass attr
		DCMAttributeTag *sopClassTag = [DCMAttributeTag tagWithName:@"AffectedSOPClassUID"];
		DCMAttribute *sopClassAttr = [DCMAttribute attributeWithAttributeTag:sopClassTag  vr:@"UI"  values:[NSMutableArray arrayWithObject:[DCMAbstractSyntaxUID verificationClassUID]]];
		//command field attr
		DCMAttributeTag *commandFieldTag = [DCMAttributeTag tagWithName:@"CommandField"];
		DCMAttribute *commandFieldAttr = [DCMAttribute attributeWithAttributeTag:commandFieldTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:commandField]]];
		//messsage ID attr
		DCMAttributeTag *messageIDTag = [DCMAttributeTag tagWithName:@"MessageID"];
		DCMAttribute *messageIDAttr = [DCMAttribute attributeWithAttributeTag:messageIDTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:messageID]]];
		//dataset type attr
		DCMAttributeTag *datasetTypeTag = [DCMAttributeTag tagWithName:@"DataSetType"];
		DCMAttribute *datasetTypeAttr = [DCMAttribute attributeWithAttributeTag:datasetTypeTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:datasetType]]];
		
		
		dcmObject = [[DCMObject dcmObject] retain];
		[dcmObject setAttribute:sopClassAttr];
		[dcmObject setAttribute:commandFieldAttr];
		[dcmObject setAttribute:messageIDAttr];
		[dcmObject setAttribute:datasetTypeAttr];

		groupLength = [[self data] length];
		//length attr
		DCMAttributeTag *groupLengthTag = [DCMAttributeTag tagWithName:@"CommandGroupLength"];
		DCMAttribute *groupLengthAttr = [DCMAttribute attributeWithAttributeTag:groupLengthTag  vr:@"UL"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:groupLength]]];
		[dcmObject setAttribute:groupLengthAttr];
					
	}
	return self;
}

+ (id)echoRequestWithObject:(DCMObject *)object{
	return [[[DCMCEchoRequest alloc] initWithObject:object] autorelease];
}
- (id)initWithObject:(DCMObject *)object{
	if (self = [super init]) {
		dcmObject = [object retain];
		commandField = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandField"]] value] charValue];
		messageID = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"MessageID"]] value] charValue];
		affectedSOPClassUID = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AffectedSOPClassUID"]] value] retain];
	}
	return self;
}



- (DCMObject *)dcmObject{
	return dcmObject;
}
/*
- (NSData *)data{
	DCMDataContainer *container = [DCMDataContainer dataContainer];
	if ([dcmObject writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] 
			quality:DCMLosslessQuality
			asDICOM3:NO
			strippingGroupLengthLength:NO]){
		return [container dicomData];
	}
	return nil;
}
*/

		
		

@end
