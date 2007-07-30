//
//  DCMCMoveResponse.m
//  OsiriX
//
//  Created by Lance Pysher on 2/12/05.

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
#import "DCMCMoveResponse.h"
#import "DCM.h"

/*statuses
	// possible statuses at this point are:
	// A701 Refused - Out of Resources - Unable to calculate number of matches
	// A702 Refused - Out of Resources - Unable to perform sub-operations
	// A801 Refused - Move Destination unknown	
	// A900 Failed - Identifier does not match SOP Class	
	// Cxxx Failed - Unable to process	
	// FE00 Cancel -Sub-operations terminated due to Cancel Indication	
	// B000 Warning	Sub-operations Complete - One or more Failures	
	// 0000 Success - Sub-operations Complete - No Failures	
	// FF00 Pending - Matches are continuing
*/




@implementation DCMCMoveResponse

+ (id)cMoveResponseWithObject:(DCMObject *)aObject{
	return [[[ DCMCMoveResponse alloc] initWithObject:aObject] autorelease];
}

+ (id)cMoveResponseWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus{
		
	return [[[ DCMCMoveResponse alloc] initWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus] autorelease];
}

- (id)initWithObject:(DCMObject *)aObject{
	if (self = [super init]) {
		dcmObject = [aObject retain];
		groupLength = [(NSNumber *)[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandGroupLength"]] intValue];
		affectedSOPClassUID = [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AffectedSOPClassUID"]] retain];
		commandField = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"CommandField"]] value] intValue];
		messageIDBeingRespondedTo = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"MessageIDBeingRespondedTo"]]  value] intValue];
		status = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Status"]] value] intValue];
		remainingSuboperations = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"NumberOfRemainingSuboperations"]] value] intValue];
		completedSuboperations = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"NumberOfCompletedSuboperations"]] value] intValue];
		failedSuboperations = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"NumberOfFailedSuboperations"]] value] intValue];
		warningSuboperations = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"NumberOfWarningSuboperations"]] value] intValue];
	}
	return self;
}

- (id)initWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus{

	if (self = [super init]) {
		affectedSOPClassUID = [classUID retain];
		commandField = 0x8021;	// C-Move-RSP
		messageIDBeingRespondedTo = messageIDBRT;
		status = aStatus;
		priority = aPriority;
		remainingSuboperations = rso;
		completedSuboperations = cso;
		failedSuboperations = fso;
		warningSuboperations = wso;
		datasetType = 0x0001;	// anything other than 0x0101 (none)
		
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
		//Priority
		//DCMAttributeTag *priorityTag = [DCMAttributeTag tagWithName:@"Priority"];
		//DCMAttribute *priorityAttr = [DCMAttribute attributeWithAttributeTag:priorityTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:priority]]];
		//Remaining suboperations
		DCMAttributeTag *remainingTag = [DCMAttributeTag tagWithName:@"NumberOfRemainingSuboperations"];
		DCMAttribute *remainingAttr = [DCMAttribute attributeWithAttributeTag:remainingTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:remainingSuboperations]]];
		//Completed suboperations
		DCMAttributeTag *completedTag = [DCMAttributeTag tagWithName:@"NumberOfCompletedSuboperations"];
		DCMAttribute *completedAttr = [DCMAttribute attributeWithAttributeTag:completedTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:completedSuboperations]]];
		//Failed suboperations
		DCMAttributeTag *failedTag = [DCMAttributeTag tagWithName:@"NumberOfFailedSuboperations"];
		DCMAttribute *failedAttr = [DCMAttribute attributeWithAttributeTag:failedTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:failedSuboperations]]];
				//Warning suboperations
		DCMAttributeTag *warningTag = [
		DCMAttributeTag tagWithName:@"NumberOfWarningSuboperations"];
		DCMAttribute *warningAttr = [DCMAttribute attributeWithAttributeTag:warningTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:warningSuboperations]]];
		

		
		
		
		dcmObject = [[DCMObject dcmObject] retain];
		[dcmObject setAttribute:sopClassAttr];
		[dcmObject setAttribute:commandFieldAttr];
		[dcmObject setAttribute:messageIDAttr];
		[dcmObject setAttribute:datasetTypeAttr];
		[dcmObject setAttribute:statusAttr];
		//[dcmObject setAttribute:priorityAttr];	
		[dcmObject setAttribute:remainingAttr];	
		[dcmObject setAttribute:completedAttr];	
		[dcmObject setAttribute:failedAttr];	
		[dcmObject setAttribute:warningAttr];	

		groupLength = [[self data] length];
		//length attr
		DCMAttributeTag *groupLengthTag = [DCMAttributeTag tagWithName:@"CommandGroupLength"];
		DCMAttribute *groupLengthAttr = [DCMAttribute attributeWithAttributeTag:groupLengthTag  vr:@"UL"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:groupLength]]];
		[dcmObject setAttribute:groupLengthAttr];
	}
	return self;
}


@end
