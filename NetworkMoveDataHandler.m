//
//  NetworkReceiveDataHandler.m
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


#import "NetworkMoveDataHandler.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>
#import "browserController.h"

extern BrowserController *browserWindow; 


@implementation NetworkMoveDataHandler

+ (id)moveDataHandler{
	return [[[NetworkMoveDataHandler alloc] initWithDebugLevel:0] autorelease];
}

- (id)initWithDebugLevel:(int)debug{
	if (self = [super initWithDebugLevel:debug])
		NSLog(@"Init NetworkMoveHandler");
	return self;
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{
	[super evaluateStatusAndSetSuccess:(DCMObject *)object];
	[self performSelectorOnMainThread:@selector(updateLogEntry:) withObject:object waitUntilDone:NO];
}

- (void)updateLogEntry:(DCMObject *)object{
	//NSLog(@"Update move log: %@", [object description]);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[object retain];
	NS_DURING
	
		if (!logEntry) {
			logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:[browserWindow managedObjectContext]];
			[logEntry setValue:[NSDate date] forKey:@"startTime"];
			[logEntry setValue:@"Move" forKey:@"type"];
			[logEntry setValue:calledAET forKey:@"originName"];
		}
		
		int totalOperations = failedSuboperations + 
		[[object attributeValueWithName:@"NumberOfCompletedSuboperations"] intValue] + 
		[[object attributeValueWithName:@"NumberOfRemainingSuboperations"] intValue];
			
		[logEntry setValue:[NSNumber numberWithInt:totalOperations] forKey:@"numberImages"];
		[logEntry setValue:[object attributeValueWithName:@"NumberOfCompletedSuboperations"]forKey:@"numberSent"];
		[logEntry setValue:[object attributeValueWithName:@"NumberOfRemainingSuboperations"] forKey:@"numberPending"];

		[logEntry setValue:[object attributeValueWithName:@"NumberOfFailedSuboperations"] forKey:@"numberError"];
		//[logEntry setValue:[object attributeValueWithName:@"Status"] forKey:@"status"];
		//[logEntry setValue:calledAET forKey:@"calledAET"];
		status = [[object attributeValueWithName:@"Status"] intValue];
		NSString *message;
		switch (status) {
			case 0xA701: message = @"Refused - Out of Resources - Unable to calculate number of matches";
				break;
			case 0xA702: message = @"Refused - Out of Resources - Unable to perform sub-operations";
				break;
			case 0xA801:message = @"Refused - Move Destination unknown";
				break;
			case 0xA900:message = @"Failed - Identifier does not match SOP Class";
				break;
			case 0xFE00:message = @"Cancel - Sub-operations terminated due to Cancel Indication";
				break;
			case 0xB000:message = @"Warning	Sub-operations Complete - One or more Failures";
				break;
			case 0xFF00:message = @"Pending - Matches are continuing";
				break;
			case 0x0000: message = @"Complete";
				[logEntry setValue:[NSNumber numberWithInt:0] forKey:@"numberPending"];	
				break;
			default: message = @"Unable to process";
		
		}
		[logEntry setValue:message forKey:@"message"];
		[logEntry setValue:[NSDate date] forKey:@"endTime"];
	NS_HANDLER
		NSLog(@"Error Updating retrieve status: %@", [localException description]);
	NS_ENDHANDLER
	[object release];
	[pool release];
	
}

- (void) dealloc {
	[logEntry setValue:[NSDate date] forKey:@"endTime"];
	[logEntry setValue:@"complete" forKey:@"message"];
	//NSLog(@"logEntry: %@", [logEntry description]);
	[super dealloc];
}


	

@end
