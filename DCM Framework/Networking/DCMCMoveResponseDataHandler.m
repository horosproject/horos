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


#import "DCMCMoveResponseDataHandler.h"
#import "DCM.h"
#import "DCMNetworking.h"

@implementation DCMCMoveResponseDataHandler

+ (id)moveResponseDataHanderWithDebugLevel:(int)debug{
	return [[[DCMCMoveResponseDataHandler alloc] initWithDebugLevel:debug] autorelease];
}

- (id)initWithDebugLevel:(int)debug{
	if (self = [super initWithDebugLevel:(int)debug]) {
		failedSuboperations = 0;
		allowData = YES;
		//date = [[NSDate date] retain];
	}
	return self;
}

- (void)dealloc{
	[calledAET release];
	[super dealloc];
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object {
	if (debugLevel > 0) NSLog(@"MoveSOPClassSCU.CFindResponseHandler.evaluateStatusAndSetSuccess:");
	if (debugLevel > 0) NSLog([object description]);
	
	// - AffectedSOPClassUID is what we sent
	// - CommandField is 0x8021 C-MOVE-RSP
	// - MessageIDBeingRespondedTo is what we sent
	// - DataSetType is 0101 for success (no data set) or other for pending
	// - Status is success and consider associated elements
	//
	// for now just treat success or warning as success (and absence as failure)
	
	status = [[object attributeValueWithName:@"Status"] intValue];
	
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
	
	//if (debugLevel)
		NSLog(@"Move status: 0x%04X", status);
	failedSuboperations = [[object attributeValueWithName:@"NumberOfFailedSuboperations"] intValue];
	//NSString *calledAET = (NSString *)[info objectForKey:@"CalledAET"];
	/************ need to un comment this to monitor moves ****************/
	if (status != 0xFF00)
		isDone = YES;
	success = status == 0x0000;		// success
	/*

	switch (status) {
		case 0xA701: log = @"Refused - Out of Resources - Unable to calculate number of matches";
			break;
		case 0xA702: log = @"Refused - Out of Resources - Unable to perform sub-operations";
			break;
		case 0xA801:log = @"Refused - Move Destination unknown";
			break;
		case 0xA900:log = @"Failed - Identifier does not match SOP Class";
			break;
		case 0xFE00:log = @"Cancel - Sub-operations terminated due to Cancel Indication";
			break;
		case 0xB000:log = @"Warning	Sub-operations Complete - One or more Failures";
			break;
		case 0xFF00:log = @"Pending - Matches are continuing";
			break;
		case 0x0000: log = @"Complete";
			break;
		default: log = @"Unable to process";
		}

	*/
}

- (void)makeUseOfDataSet:(DCMObject *)object{
	// we only get here if there are failed sub-operations, in which case we get a list
	// in Failed SOP Instance UID List (0008,0058)
	NSLog(@"Failed Move: %@", [object description]);
	isDone = YES;
}


	
	

@end
