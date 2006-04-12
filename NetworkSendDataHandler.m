//
//  NetworkSendDataHandler.m
//  OsiriX
//
//  Created by Lance Pysher on 5/31/05.

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


#import "NetworkSendDataHandler.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>
#import "browserController.h"

extern BrowserController *browserWindow; 


@implementation NetworkSendDataHandler

- (id)initWithDebugLevel:(int)debug{
	if (self = [super initWithDebugLevel:debug])
	{
		logEntry = 0L;
	}
	return self;
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{
	[super evaluateStatusAndSetSuccess:(DCMObject *)object];
	[self performSelectorOnMainThread:@selector(updateLogEntry:) withObject:object waitUntilDone:YES];
		
}

- (void)updateLogEntry:(DCMObject *)object
{
	[object retain];
	NSManagedObjectContext *context = [browserWindow managedObjectContext];
	[context lock];
	
	if (!logEntry) {
		NSString *patientName = [currentObject attributeValueWithName:@"PatientsName"];
		NSString *studyDescription = [currentObject attributeValueWithName:@"StudyDescription"];
		
		logEntry = [[NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context] retain];
		[logEntry setValue:[NSDate date] forKey:@"startTime"];
		[logEntry setValue:@"Send" forKey:@"type"];
		[logEntry setValue:calledAET forKey:@"destinationName"];
		[logEntry setValue:calledAET forKey:@"originName"];
		if (patientName)
			[logEntry setValue:patientName forKey:@"patientName"];
		if (studyDescription)
			[logEntry setValue:studyDescription forKey:@"studyName"];
	}	
	[logEntry setValue:[NSNumber numberWithInt:numberOfFiles] forKey:@"numberImages"];
	[logEntry setValue:[NSNumber numberWithInt:numberSent] forKey:@"numberSent"];
	[logEntry setValue:[NSNumber numberWithInt:numberErrors] forKey:@"numberError"];
	if (numberSent + numberErrors < numberOfFiles) {
		[logEntry setValue:@"in progress" forKey:@"message"];
	}
	else{
		[logEntry setValue:@"complete" forKey:@"message"];
	
	}
	[logEntry setValue:[NSDate date] forKey:@"endTime"];
	[object release];
	[context unlock];
}

- (void) dealloc {
	[logEntry setValue:[NSDate date] forKey:@"endTime"];
	[logEntry setValue:@"complete" forKey:@"message"];
	[logEntry release];
	[super dealloc];
}

@end
