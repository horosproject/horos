//
//  DCMNCreateRequest.m
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

#import "DCMNCreateRequest.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMNCreateRequest

+ (NSString *)newUID{
	NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSArray *values = [globallyUniqueString componentsSeparatedByString:@"-"];
	NSMutableArray *newUIDValues = [NSMutableArray array];
	for ( NSString *string in values ) {
		unsigned int hexValue;
		NSScanner *scanner = [NSScanner scannerWithString:string];
		[scanner scanHexInt:&hexValue];
		NSString *newValue = [NSString stringWithFormat:@"%u", hexValue];
		//NSLog(@"string %@ newValue: %d",string,(int)fabs(hexValue));
		[newUIDValues addObject:newValue];
	}
	NSString *uidSuffix = [newUIDValues componentsJoinedByString:@""];
	
	NSString *rootUID = [DCMObject rootUID];
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"3", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	uid = [uid substringToIndex:64];
	return uid;
}

+ (id) filmSessionInColor:(BOOL)isColor{	
	NSString *sopClass = [DCMAbstractSyntaxUID  basicGrayscalePrintManagementMetaSOPClassUID];
	if (isColor)
		sopClass = [DCMAbstractSyntaxUID  basicColorPrintManagementMetaSOPClassUID];
	return [DCMNCreateRequest nCreateRequestWithSopClassUID:sopClass
		sopInstanceUID:[DCMNCreateRequest newUID]
		hasDataset:YES];
}


+ (id) filmBox{
		return [DCMNCreateRequest nCreateRequestWithSopClassUID:@"1.2.840.10008.5.1.1.2" 
		sopInstanceUID:[DCMNCreateRequest newUID]
		hasDataset:YES];
}

+ (id)nCreateRequestWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		hasDataset:(BOOL)hasDataset{
	return [[[DCMNCreateRequest alloc] initWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		hasDataset:(BOOL)hasDataset] autorelease];
}

- (id)initWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		hasDataset:(BOOL)hasDataset{
			
	if (self = [super init]) {
		commandField = 0x0140;
		messageID = 0x0001;
		if (hasDataset) 
			datasetType = 0x0001;  // have a dataset.
		else
			datasetType = 0x0101;
		
		affectedSOPClassUID = [sopClassUID retain];
		affectedSOPInstanceUID = [sopInstanceUID retain];
				
		dcmObject = [[DCMObject dcmObject] retain];
		//sopClass attr
		[dcmObject addAttributeValue:sopClassUID  forName:@"AffectedSOPClassUID"];
		
		//command field attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:commandField]   forName:@"CommandField"];

		//messsage ID attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:messageID]   forName:@"MessageID"];

		//dataset type attr
		[dcmObject addAttributeValue:[NSNumber numberWithInt:datasetType]   forName:@"DataSetType"];
		
		
		//sopInstance attr
		[dcmObject addAttributeValue:sopInstanceUID   forName:@"AffectedSOPInstanceUID"];
		
		//group length
		groupLength = [[self data] length];
		[dcmObject addAttributeValue:[NSNumber numberWithInt:groupLength]   forName:@"CommandGroupLength"];
	}
	return self;
}

@end
