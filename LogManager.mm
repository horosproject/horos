//
//  LogManager.mm
//  OsiriX
//
//  Created by Lance Pysher on 4/21/06.

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

#import "LogManager.h"
#import "browserController.h"

LogManager *currentLogManager;


@implementation LogManager

+ (id)currentLogManager{
	if (!currentLogManager)
		currentLogManager = [[LogManager alloc] init];
	return currentLogManager;
}

- (id)init{
	if (self = [super init]){
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLog:) name:@"DCMTKUpdateReceive" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLog:) name:@"DCMTKCompleteReceive" object:nil];
		
	}
	return self;
}

- (void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}



- (void)updateLog:(NSNotification *)note{
//	[self checkLogs:[note userInfo]];
	[self performSelectorOnMainThread:@selector(checkLogs:) withObject: [note userInfo] waitUntilDone:NO];  
}

- (void)removeLog:(NSNotification *)note{
//	[self checkLogs:[note userInfo]];
	[self performSelectorOnMainThread:@selector(checkLogs:) withObject: [note userInfo] waitUntilDone:NO];  
}

- (void)checkLogs:(NSDictionary *)logInfo{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	NSLog(@"check logs - logInfo: %@", [logInfo description]);
	NS_DURING
	
	//create logEntry and add to _logs
		id logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
		[logEntry setValue:[logInfo objectForKey:@"startTime"] forKey:@"startTime"];
		[logEntry setValue:@"Receive" forKey:@"type"];
		[logEntry setValue:[logInfo objectForKey:@"CallingAET"] forKey:@"originName"];
		[logEntry setValue:[logInfo objectForKey:@"PatientName"] forKey:@"patientName"];
		[logEntry setValue:[logInfo objectForKey:@"StudyDescription"] forKey:@"studyName"];
	
		
	
	//update logEntry
	[logEntry setValue:[logInfo objectForKey:@"Message"] forKey:@"message"];
	[logEntry setValue:[logInfo objectForKey:@"NumberReceived"] forKey:@"numberImages"];
	[logEntry setValue:[logInfo objectForKey:@"NumberReceived"  ] forKey:@"numberSent"];
	[logEntry setValue:[logInfo objectForKey:@"ErrorCount"] forKey:@"numberError"];
	[logEntry setValue:[logInfo objectForKey:@"endTime"] forKey:@"endTime"];
	NSLog(@"create logs - logInfo: %@", [logEntry description]);



	NS_HANDLER
		NSLog(@"Exception while checking logs: %@", [localException description]);
	NS_ENDHANDLER

}

@end
