//
//  DCMNAction.m
//  OsiriX
//
//  Created by Lance Pysher on 9/2/05.

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


#import "DCMNActionRequest.h"
#import "DCM.h"


@implementation DCMNActionRequest

+ (id)nActionRequestWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		actionTypeID:(unsigned short)actionTypeID
		hasDataset:(BOOL)hasDataset{
		
		return [[[DCMNActionRequest alloc] initWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		actionTypeID:(unsigned short)actionTypeID
		hasDataset:(BOOL)hasDataset] autorelease];
}

- (id)initWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		actionTypeID:(unsigned short)actionTypeID
		hasDataset:(BOOL)hasDataset
{
	
	if (self = [super init]) {
		commandField = 0x0130;
		messageID = 0x0001;
		if (hasDataset) 
			datasetType = 0x0001;  // have a dataset.
		else
			datasetType = 0x0101;
		
		affectedSOPClassUID = [sopClassUID retain];
		affectedSOPInstanceUID = [sopInstanceUID retain];
		actionType = actionTypeID;
				
		dcmObject = [[DCMObject dcmObject] retain];
		//sopClass attr
		[dcmObject addAttributeValue:sopClassUID  forName:@"AffectedSOPClassUID"];
		
		//command field attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:commandField]   forName:@"CommandField"];

		//messsage ID attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:messageID]   forName:@"MessageID"];

		//dataset type attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:datasetType]   forName:@"DataSetType"];
		
		//actionType type attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:actionTypeID]   forName:@"ActionTypeID"];
		
		//sopInstance attr
		[dcmObject addAttributeValue:sopInstanceUID   forName:@"AffectedSOPInstanceUID"];
		
		//group length
		groupLength = [[self data] length];
		[dcmObject addAttributeValue:[NSNumber numberWithInt:groupLength]   forName:@"CommandGroupLength"];
	}
	return self;
}

@end
