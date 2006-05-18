//
//  DCMCStoreResponseHandler.m
//  OsiriX
//
//  Created by Lance Pysher on 12/20/04.

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

#import "DCMCStoreResponseHandler.h"
#import "DCM.h"

@implementation DCMCStoreResponseHandler

- (id)initWithDebugLevel:(int)debug{
	 if (self = [super initWithDebugLevel:debug]){
		currentObject = nil;
		numberOfFiles = 0;
		numberSent = 0;
		numberErrors = 0;
	}
	return self;
}

- (void)dealloc{
	NSLog(@"Number of Files: %d  number sent: %d  number of errors:%d", numberOfFiles, numberSent,  numberErrors);
	[currentObject release];
	[super dealloc];
}


- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{
	//NSLog(@"cStore response: %@", [object description]);
	unsigned short moveStatus;
	status = [[object  attributeValueWithName:@"Status"] intValue];
	success =  (status == 0x0000	// success
				|| status == 0xB000	// coercion of data element
				|| status == 0xB007	// data set does not match SOP Class
				|| status == 0xB006);	// element discarded
	if (success) {
		numberSent++;
		moveStatus = 0xFF00;
	}
	else {
		numberErrors++;
		moveStatus = 0xA702;
	}
		/*
		@"PatientName"
		@"StudyDescription"
		@"StudyID"
		*/
		
	
	NSString *patientName = [currentObject attributeValueWithName:@"PatientsName"];
	NSString *studyDescription = [currentObject attributeValueWithName:@"StudyDescription"];
	NSString *studyID = [currentObject attributeValueWithName:@"studyID"];
		
	NSMutableDictionary  *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:numberOfFiles] forKey:@"SendTotal"];
	[userInfo setObject:[NSNumber numberWithInt:numberSent] forKey:@"NumberSent"];
	[userInfo setObject:[NSNumber numberWithInt:numberErrors] forKey:@"ErrorCount"];
	if (numberSent + numberErrors < numberOfFiles) {
		[userInfo setObject:[NSNumber numberWithInt:NO] forKey:@"Sent"];
		[userInfo setObject:@"In Progress" forKey:@"Message"];
	}
	else{
		[userInfo setObject:[NSNumber numberWithInt:YES] forKey:@"Sent"];
		[userInfo setObject:@"Complete" forKey:@"Message"];
		moveStatus = 0x0000;
		NSLog(@"move Complete");
	}
		
	if (calledAET)
		[userInfo setObject:calledAET forKey:@"CalledAET"];		
	if (patientName)
		[userInfo setObject:patientName forKey:@"PatientName"];		
	if (studyDescription)
		[userInfo setObject:studyDescription forKey:@"StudyDescription"];	
	else if ([currentObject attributeValueWithName:@"StudyID"])
		[userInfo setObject:[currentObject attributeValueWithName:@"StudyID"] forKey:@"StudyDescription"];
	else
		[userInfo setObject:@"unknown" forKey:@"StudyDescription"];
	if (studyID)
		[userInfo setObject:studyID forKey:@"StudyID"];
	if (date)
		[userInfo setObject:date forKey:@"Time"];
	

	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMSendStatus" object:self userInfo:userInfo];
	
	[moveHandler setStatus:(unsigned short)moveStatus  numberSent:(int)numberSent numberError:(int)numberErrors];
	//NSLog(@"Status: 0x%x", moveStatus);
}

- (void)setCurrentObject:(DCMObject *)object{
	[currentObject release];
	currentObject = [object retain];
}
- (DCMObject *)currentObject{
	return currentObject;
}
- (void)setNumberOfFiles:(int)number{
	numberOfFiles = number;
}
- (int)numberOfFiles{
	return numberOfFiles;
}
- (int)numberSent{
	return numberSent;
}
- (int)numberErrors{
	return numberErrors;
}

- (void)setMoveHandler:(id)handler{
	moveHandler = handler;
}
	

@end
