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


/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMReceivedDataHandler.h"


@implementation DCMReceivedDataHandler

- (void)dumpPDVList:(NSArray *)pdvs{
}

- (void)sendPDataIndication:(DCMPDataPDU *)pdu   association:(DCMAssociation *)association{
}

- (BOOL)isDone{
	return isDone;
}

- (void)setIsDone:(BOOL)value{
	isDone = value;
}

- (id)initWithDebugLevel:(int)debug{
	if (self = [super init]){
		debugLevel = debug;
		isDone = NO;
	}
	return self;
}

- (void)dealloc{
	//[commandReceived release];
	//[dataReceived release];
	[super dealloc];
}

- (void)setCallingAET:(NSString *)aet{
}

@end
