//
//  DCMNGetRequest.m
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

#import "DCMNGetRequest.h"
#import "DCM.h"


@implementation DCMNGetRequest

+ (id)nGetRequestWithAttributeList:(NSArray *)attributeList
		sopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID {
	return [[[DCMNGetRequest alloc] initWithAttributeList:attributeList
			sopClassUID:(NSString *)sopClassUID  
			sopInstanceUID:(NSString *)sopInstanceUID] autorelease];
}

- (id)initWithAttributeList:(NSArray *)attributeList  
		sopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID
{
	
	if (self = [super init]) {
		commandField = 0x0110;
		messageID = 0x0001;
		datasetType = 0x0101;
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
		
		for ( NSNumber *attr in attributeList )
			[dcmObject addAttributeValue:attr   forName:@"AttributeIdentifierList"];
		
		//group length
		groupLength = [[self data] length];
		[dcmObject addAttributeValue:[NSNumber numberWithInt:groupLength]   forName:@"CommandGroupLength"];
	}
	return self;
}

@end
