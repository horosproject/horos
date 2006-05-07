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
		_currentLogs = [[NSMutableDictionary alloc] init];
		_timer = [[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkLogs:) userInfo:nil repeats:YES] retain];
		
	}
	return self;
}

- (void)dealloc{
	[_currentLogs release];
	[_timer invalidate];
	[_timer release];
	[super dealloc];
}

- (NSString *)logFolder{
	NSString *path =  [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@".logs"];
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDir;
	if (!([manager fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
		[manager createDirectoryAtPath:path attributes:nil];
	}
	return path;
}

- (void)checkLogs:(NSTimer *)timer
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"NETWORKLOGS"])
	{
		NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];	
		NSFileManager *manager = [NSFileManager defaultManager];
		NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:[self logFolder]];
		NSString *path;
		
		[context lock];
		
		NS_DURING
		while (path = [enumerator nextObject]){
			if ([[path pathExtension] isEqualToString: @"plist"]) {
				
				NSString *file = [[self logFolder] stringByAppendingPathComponent:path];
				NSDictionary *logInfo = [NSDictionary dictionaryWithContentsOfFile:file];
				//delete file
				[manager removeFileAtPath:file handler:nil];
				
				NSString *uid = [logInfo objectForKey:@"uid"];
				id logEntry = [_currentLogs objectForKey:uid];
				if (logEntry == nil) {
			//create logEntry and add to _logs
					logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
					[logEntry setValue:[logInfo objectForKey:@"startTime"] forKey:@"startTime"];
					[logEntry setValue:@"Receive" forKey:@"type"];
					[logEntry setValue:[logInfo objectForKey:@"CallingAET"] forKey:@"originName"];
					[logEntry setValue:[logInfo objectForKey:@"PatientName"] forKey:@"patientName"];
					[logEntry setValue:[logInfo objectForKey:@"StudyDescription"] forKey:@"studyName"];
					[_currentLogs setObject:logEntry forKey:uid];
				}
					
				
				//update logEntry
				[logEntry setValue:[logInfo objectForKey:@"message"] forKey:@"message"];
				[logEntry setValue:[logInfo objectForKey:@"numberReceived"] forKey:@"numberImages"];
				[logEntry setValue:[logInfo objectForKey:@"numberReceived"  ] forKey:@"numberSent"];
				[logEntry setValue:[logInfo objectForKey:@"errorCount"] forKey:@"numberError"];
				[logEntry setValue:[logInfo objectForKey:@"endTime"] forKey:@"endTime"];
				
				if ([[logInfo objectForKey:@"message"] isEqualToString:@"Complete"]) {
					[_currentLogs removeObjectForKey:uid];
					NSLog(@"Remove %@ on completion", uid);
				}
			}
			
		}

		NS_HANDLER
			NSLog(@"Exception while checking logs: %@", [localException description]);
		NS_ENDHANDLER
		
		[context unlock];
	}
}

@end
