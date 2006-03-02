/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Foundation/Foundation.h>


@class  PMDICOMStoreSCU;
@class DCMTransferSyntax;

@interface DICOMStoreSCU : NSObject {
	NSString *callingAET;
	NSString *calledAET;
	NSString *hostname;
	int port;
	//NSString *port;
	NSArray *files;
	PMDICOMStoreSCU *storeSCU;
	DCMTransferSyntax *transferSyntax;
	int quality;


}

//- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort files:(NSArray *)filenames;
- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort files:(NSArray *)filenames transferSyntax:(DCMTransferSyntax*)ts quality:(int)q;
-(BOOL)send:(NSString *)file;
-(void)startSend:(id)sender;

@end
