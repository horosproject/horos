/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "NetworkMoveDataHandler.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>
#import "browserController.h"



@implementation NetworkMoveDataHandler

+ (id)moveDataHandler{
	return [[[NetworkMoveDataHandler alloc] initWithDebugLevel:0] autorelease];
}

- (id)initWithDebugLevel:(int)debug{
	if (self = [super initWithDebugLevel:debug])
	{
//		NSLog(@"Init NetworkMoveHandler");
		logEntry = nil;
	}
	return self;
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{
	[super evaluateStatusAndSetSuccess:(DCMObject *)object];
	[self performSelectorOnMainThread:@selector(updateLogEntry:) withObject:object waitUntilDone:YES];
}

- (void)updateLogEntry:(DCMObject *)object
{
	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO) return;

	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
	if( context == nil) return;
	
	[object retain];
	NS_DURING
	
		if (!logEntry) {
			logEntry = [[NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context] retain];
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
}

- (void) dealloc {
	if( logEntry)
	{
		[logEntry setValue:[NSDate date] forKey:@"endTime"];
		[logEntry setValue:@"Complete" forKey:@"message"];
		[logEntry release];
	}
	[super dealloc];
}


@end
