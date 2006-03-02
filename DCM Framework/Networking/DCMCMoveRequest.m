//
//  DCMCMoveRequest.m
//  OsiriX
//
//  Created by Lance Pysher on 12/31/04.

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

#import "DCMCMoveRequest.h"
#import "DCM.h"
#import "DCMNetworking.h"

@implementation DCMCMoveRequest

+ (id)moveRequestWithAffectedSOPClassUID:(NSString *)classUID moveDestination:(NSString *)destination{
	return [[[DCMCMoveRequest alloc] initWithAffectedSOPClassUID:(NSString *)classUID moveDestination:(NSString *)destination] autorelease];
}

+ (id)moveRequestWithObject:(DCMObject *)object{
	return [[[DCMCMoveRequest alloc] initWithObject:(DCMObject *)object] autorelease];
}

- (id)initWithObject:(DCMObject *)object{
	if (self = [super init]) {
		dcmObject = [object retain];
		commandField = [[dcmObject attributeValueWithName:@"CommandField"] shortValue];
		messageID = [[dcmObject attributeValueWithName:@"MessageID"] shortValue];
		affectedSOPClassUID = [[dcmObject attributeValueWithName:@"AffectedSOPClassUID"] retain];
		priority = [[dcmObject attributeValueWithName:@"Priority"] shortValue];
		moveDestination = [[dcmObject attributeValueWithName:@"MoveDestination"] retain];
	}
	return self;
}

- (id)initWithAffectedSOPClassUID:(NSString *)classUID moveDestination:(NSString *)destination{
if (self = [super init]) {
		affectedSOPClassUID = [classUID retain];
		moveDestination = [destination retain];
		commandField = 0x0021;	// C-Move-RQ
		messageID = 0x0001;
		priority = 0x0000;	// MEDIUM
		datasetType = 0x0001;	// anything other than 0x0101 (none), since a C-FIND-RQ always has a data set (the "identifier")
		//NSLog(@"Move Request affected class: %@  destination:%@", classUID, destination);
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
		//Move Destination
		DCMAttributeTag *destinationTag = [DCMAttributeTag tagWithName:@"MoveDestination"];
		DCMAttribute *destinationAttr = [DCMAttribute attributeWithAttributeTag:destinationTag  vr:@"AE"  values:[NSMutableArray arrayWithObject:moveDestination]];

		
		
		dcmObject = [[DCMObject dcmObject] retain];
		[dcmObject setAttribute:sopClassAttr];
		[dcmObject setAttribute:commandFieldAttr];
		[dcmObject setAttribute:messageIDAttr];
		[dcmObject setAttribute:datasetTypeAttr];
		[dcmObject setAttribute:priorityAttr];
		[dcmObject setAttribute:destinationAttr];
		
		//NSLog(@"Move request:%@", [dcmObject description]);

		groupLength = [[self data] length];
		//length attr
		DCMAttributeTag *groupLengthTag = [DCMAttributeTag tagWithName:@"CommandGroupLength"];
		DCMAttribute *groupLengthAttr = [DCMAttribute attributeWithAttributeTag:groupLengthTag  vr:@"UL"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:groupLength]]];
		[dcmObject setAttribute:groupLengthAttr];
		
	}
	return self;

}

- (void)dealloc{
	[moveDestination release];
	[super dealloc];
}

- (int)priority{
	return priority;
}

- (NSString *)moveDestination{
	return moveDestination;
}

@end
