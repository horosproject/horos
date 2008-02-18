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


/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

/*status
	// possible statuses at this point are:
	// A700 Refused - Out of Resources	
	// A900 Failed - Identifier does not match SOP Class	
	// Cxxx Failed - Unable to process	
	// FE00 Cancel - Matching terminated due to Cancel request	
	// 0000 Success - Matching is complete - No final Identifier is supplied.	
	// FF00 Pending - Matches are continuing - Current Match is supplied and any Optional Keys were supported in the same manner as Required Keys.
	// FF01 Pending - Matches are continuing - Warning that one or more Optional Keys were not supported for existence and/or matching for this Identifier.

*/


#import "DCMCFindResponse.h"
#import "DCM.h"


@implementation DCMCFindResponse

+ (id)cFindResponseWithObject:(DCMObject *)aObject{
	return [[[ DCMCFindResponse alloc] initWithObject:aObject] autorelease];
}

+ (id)cFindResponseWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus{
	return [[[ DCMCFindResponse alloc] initWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus] autorelease];
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
		commandField = 0x8020;	// C-Find-RSP  
		messageIDBeingRespondedTo = messageIDBRT;
		status = aStatus;
		priority = aPriority;
		remainingSuboperations = rso;
		completedSuboperations = cso;
		failedSuboperations = fso;
		warningSuboperations = wso;
		if (status == 0xFF00) //pending
			datasetType = 0x0001;  //dataset to follow
		else
			datasetType = 0x0101; //no dataset to follow
			
	
		
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
		/*
		DCMAttributeTag *priorityTag = [DCMAttributeTag tagWithName:@"Priority"];
		DCMAttribute *priorityAttr = [DCMAttribute attributeWithAttributeTag:priorityTag  vr:@"US"  values:[NSMutableArray arrayWithObject:[NSNumber numberWithShort:priority]]];
		*/
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
	//	[dcmObject setAttribute:priorityAttr];	
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
