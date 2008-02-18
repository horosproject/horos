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


#import "DCMCFindResponseDataHandler.h"
#import "DCM.h"
#import "DCMNetworking.h"

@implementation DCMCFindResponseDataHandler

+ (id)findHandlerWithDebugLevel:(int)debug  queryNode:(DCMQueryNode *)node{
	return [[[DCMCFindResponseDataHandler alloc] initWithDebugLevel:(int)debug  queryNode:(DCMQueryNode *)node] autorelease];
}

- (id)initWithDebugLevel:(int)debug{
/*
	if (self = [super initWithDebugLevel:(int)debug])
		allowData = YES;
	return self;
	*/
	return [self initWithDebugLevel:(int)debug  queryNode:nil];
}

- (id)initWithDebugLevel:(int)debug  queryNode:(DCMQueryNode *)node{
	if (self = [super initWithDebugLevel:(int)debug]) {
		allowData = YES;
		queryNode = [node retain];
		//debugLevel = 1;
	}
	return self;
}
- (DCMQueryNode *)queryNode{
	return queryNode;
}
- (void)setQueryNode:(DCMQueryNode *)node{
	[queryNode release];
	queryNode = [node retain];
}

- (void)dealloc{
	[queryNode release];
	[super dealloc];
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object {

	if (debugLevel > 0) NSLog(@"FindSOPClassSCU.CFindResponseHandler.evaluateStatusAndSetSuccess:");
	if (debugLevel > 0) NSLog([object description]);
			// could check all sorts of things, like:
			// - AffectedSOPClassUID is what we sent
			// - CommandField is 0x8020 C-Find-RSP
			// - MessageIDBeingRespondedTo is what we sent
			// - DataSetType is 0101 for success (no data set) or other for pending
			// - Status is success and consider associated elements
			//
			// for now just treat success or warning as success (and absence as failure)
		 status = [[object attributeValueWithName:@"Status"] intValue];
//if (debugLevel > 0) System.err.println("FindSOPClassSCU.CFindResponseHandler.evaluateStatusAndSetSuccess: status = 0x"+Integer.toHexString(status));
			// possible statuses at this point are:
			// A700 Refused - Out of Resources	
			// A900 Failed - Identifier does not match SOP Class	
			// Cxxx Failed - Unable to process	
			// FE00 Cancel - Matching terminated due to Cancel request	
			// 0000 Success - Matching is complete - No final Identifier is supplied.	
			// FF00 Pending - Matches are continuing - Current Match is supplied and any Optional Keys were supported in the same manner as Required Keys.
			// FF01 Pending - Matches are continuing - Warning that one or more Optional Keys were not supported for existence and/or matching for this Identifier.

			success = status == 0x0000;	// success
	if (debugLevel)
		NSLog(@"Find status: 0x%04x", status);
	if (status != 0xFF00 && status != 0xFF01) {
		if (debugLevel > 0) NSLog(@"FindSOPClassSCU.CFindResponseHandler.evaluateStatusAndSetSuccess: status no longer pending, so stop");
			isDone = YES;
	}
}

- (void)makeUseOfDataSet:(DCMObject *)object{
	//debugLevel = 1;
	if (debugLevel) {
		NSLog(@"Find Result:\n:%@", [object description]);
	//	NSLog(@"made us of Data set");
	}

	[queryNode addChild:object];
}


@end
