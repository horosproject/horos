//
//  DCMNSetRequest.m
//  OsiriX
//
//  Created by Lance Pysher on 9/2/05.

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

#import "DCMNSetRequest.h"
#import "DCM.h"


@implementation DCMNSetRequest

+ (id)nSetRequestWithSopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID {
	return [[[DCMNSetRequest alloc] initWithSopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID] autorelease];
}

- (id)initWithSopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID
{
	
	if (self = [super init]) {
		commandField = 0x0120;
		messageID = 0x0001;
		datasetType = 0x0001;  // have a dataset.
		requestedSOPClassUID = [sopClassUID retain];
		requestedSOPInstanceUID = [sopInstanceUID retain];
				
		dcmObject = [[DCMObject dcmObject] retain];
		//sopClass attr
		[dcmObject addAttributeValue:sopClassUID  forName:@"RequestedSOPClassUID"];
		
		//command field attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:commandField]   forName:@"CommandField"];

		//messsage ID attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:messageID]   forName:@"MessageID"];

		//dataset type attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:datasetType]   forName:@"DataSetType"];
		
		//sopInstance attr
		[dcmObject addAttributeValue:sopInstanceUID   forName:@"RequestedSOPInstanceUID"];
		
		//group length
		groupLength = [[self data] length];
		[dcmObject addAttributeValue:[NSNumber numberWithInt:groupLength]   forName:@"CommandGroupLength"];
	}
	return self;
}

@end
