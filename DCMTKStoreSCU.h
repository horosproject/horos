//
//  DCMTKStoreSCU.h
//  OsiriX
//
//  Created by Lance Pysher on 3/3/06.
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


#import <Cocoa/Cocoa.h>


int runStoreSCU(const char *myAET, const char*peerAET, const char*hostname, int port, NSDictionary *extraParameters);


@interface DCMTKStoreSCU : NSObject {
	NSString *_callingAET;
	NSString *_calledAET;
	int _port;
	NSString *_hostname;
	NSDictionary *_extraParameters;
	BOOL _shouldAbort;
	NSString *_transferSyntax;
	float _compression;
	NSArray *_filesToSend;
	int _numberOfFiles;
	int _numberSent;
	int _numberErrors;
	NSString *_patientName;
	NSString *_studyDescription; 
	id _logEntry;
	
	

}

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			transferSyntax:(NSString *)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (void)run:(id)sender;
- (void)updateLogEntry:(id)sender;
- (void)abort:(id)sender;
- (void)save:(id)sender;




@end
