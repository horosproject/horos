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

#import <Cocoa/Cocoa.h>


@class DCMPDataPDU;
@class DCMAssociation;
@interface DCMReceivedDataHandler : NSObject {
	BOOL isDone;
	int debugLevel;
	NSMutableData *commandReceived;
	NSMutableData *dataReceived;
}
- (id)initWithDebugLevel:(int)debug;
- (void)dumpPDVList:(NSArray *)pdvs;
- (void)sendPDataIndication:(DCMPDataPDU *)pdu   association:(DCMAssociation *)association;
- (BOOL)isDone;
- (void)setIsDone:(BOOL)value;
- (void)setCallingAET:(NSString *)aet;


@end
