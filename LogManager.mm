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
		_timer = [[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkLogs:) userInfo:nil repeats:YES] retain];
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
	NSString *path =  [[[BrowserController currentBrowser] fixedDocumentsDirectory] stringByAppendingPathComponent:@"TEMP"];
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDir;
	if (!([manager fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
		[manager createDirectoryAtPath:path attributes:nil];
	}
	return path;
}

- (void)checkLogs:(NSTimer *)timer
{
	if( [[BrowserController currentBrowser] isNetworkLogsActive])
	{
		NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];	
		NSFileManager *manager = [NSFileManager defaultManager];
		NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:[self logFolder]];
		NSString *path;

		char logPatientName[256];
		char logStudyDescription[256];
		char logCallingAET[256];
		char logStartTime[256];
		char logMessage[256];
		char logUID[256];
		char logNumberReceived[256];
		char logEndTime[256];
			
		[context lock];
		
		NS_DURING
		while (path = [enumerator nextObject]){
			if ([[path pathExtension] isEqualToString: @"log"]) {
				
				NSString *file = [[self logFolder] stringByAppendingPathComponent:path];
				
				FILE * pFile;
				pFile = fopen ( [file UTF8String], "r");
				if( pFile)
				{
					char	data[ 4096];
					
					fread( data, 4096, 1 ,pFile);
					
					char	*curData = data;
					
					strcpy( logPatientName, strsep( &curData, "\r"));
					strcpy( logStudyDescription, strsep( &curData, "\r"));
					strcpy( logCallingAET, strsep( &curData, "\r"));
					strcpy( logStartTime, strsep( &curData, "\r"));
					strcpy( logMessage, strsep( &curData, "\r"));
					strcpy( logUID, strsep( &curData, "\r"));
					strcpy( logNumberReceived, strsep( &curData, "\r"));
					strcpy( logEndTime, strsep( &curData, "\r"));
					
					fclose (pFile);
					remove( [file UTF8String]);
					
					NSString *uid = [NSString stringWithUTF8String: logUID];
					id logEntry = [_currentLogs objectForKey:uid];
					if (logEntry == nil)
					{
						logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
						
						[logEntry setValue:[NSDate dateWithTimeIntervalSince1970: [[NSString stringWithUTF8String: logStartTime] intValue]]  forKey:@"startTime"];
						[logEntry setValue:@"Receive" forKey:@"type"];
						[logEntry setValue:[NSString stringWithUTF8String: logCallingAET] forKey:@"originName"];
						[logEntry setValue:[NSString stringWithUTF8String: logPatientName] forKey:@"patientName"];
						[logEntry setValue:[NSString stringWithUTF8String: logStudyDescription] forKey:@"studyName"];
						[_currentLogs setObject:logEntry forKey:uid];
					}
					
					//update logEntry
					[logEntry setValue:[NSString stringWithUTF8String: logMessage] forKey:@"message"];
					[logEntry setValue:[NSNumber numberWithInt: [[NSString stringWithUTF8String: logNumberReceived] intValue]] forKey:@"numberImages"];
					[logEntry setValue:[NSNumber numberWithInt: [[NSString stringWithUTF8String: logNumberReceived] intValue]] forKey:@"numberSent"];
					[logEntry setValue:0 forKey:@"numberError"];
					[logEntry setValue:[NSDate dateWithTimeIntervalSince1970: [[NSString stringWithUTF8String: logEndTime] intValue]] forKey:@"endTime"];
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
