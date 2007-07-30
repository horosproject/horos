//
//  DCMEchoResponseHandler.m
//  OsiriX
//
//  Created by Lance Pysher on 12/15/04.

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
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMEchoResponseHandler.h"
#import "DCM.h"


@implementation DCMEchoResponseHandler

- (id)initWithDebugLevel:(int)debug{
	if (self = [super initWithDebugLevel:(int)debug])
		success = NO;
	return self;
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{
	status = [[[object  attributeForTag:[DCMAttributeTag tagWithName:@"Status"]] value] intValue];
	success =  status == 0x0000;	// success

}

- (void) makeUseOfDataSet:(DCMObject *)object{
	[self evaluateStatusAndSetSuccess:object];
}

- (BOOL)success{
	return success;
}

@end
