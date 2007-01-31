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
		_timer = [[NSTimer scheduledTimerWithTimeInterval: 5 target:self selector:@selector(checkLogs:) userInfo:nil repeats:YES] retain];
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
		NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
		if( context == 0L) return;
		
		BOOL locked = NO;
		
		NSFileManager *manager = [NSFileManager defaultManager];
		NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:[self logFolder]];
		NSString *path;
		
		char logPatientName[ 1024];
		char logStudyDescription[ 1024];
		char logCallingAET[ 1024];
		char logStartTime[ 1024];
		char logMessage[ 1024];
		char logUID[ 1024];
		char logNumberReceived[ 1024];
		char logEndTime[ 1024];

		logPatientName[ 0] = 0;
		logStudyDescription[ 0] = 0;
		logCallingAET[ 0] = 0;
		logStartTime[ 0] = 0;
		logMessage[ 0] = 0;
		logUID[ 0] = 0;
		logNumberReceived[ 0] = 0;
		logEndTime[ 0] = 0;
		
		NS_DURING
		while (path = [enumerator nextObject]){
			if ([[path pathExtension] isEqualToString: @"log"])
			{
				if( locked == NO) locked = [context tryLock];
				
				if( locked)
				{
					NSString *file = [[self logFolder] stringByAppendingPathComponent:path];
					NSString *newfile = [file stringByAppendingString:@"reading"];
					
					rename( [file UTF8String], [newfile UTF8String]);
					remove( [file UTF8String]);
					
					FILE * pFile;
					pFile = fopen ( [newfile UTF8String], "r");
					if( pFile)
					{
						char	data[ 4096];
						
						fread( data, 4096, 1 ,pFile);
						
						char	*curData = data;
						
						if(curData) strcpy( logPatientName, strsep( &curData, "\r"));
						if(curData) strcpy( logStudyDescription, strsep( &curData, "\r"));
						if(curData) strcpy( logCallingAET, strsep( &curData, "\r"));
						if(curData) strcpy( logStartTime, strsep( &curData, "\r"));
						if(curData) strcpy( logMessage, strsep( &curData, "\r"));
						if(curData) strcpy( logUID, strsep( &curData, "\r"));
						if(curData) strcpy( logNumberReceived, strsep( &curData, "\r"));
						if(curData) strcpy( logEndTime, strsep( &curData, "\r"));
						
						fclose (pFile);
						remove( [newfile UTF8String]);
						
						if( [[NSString stringWithUTF8String: logMessage] isEqualToString:@"In Progress"] || [[NSString stringWithUTF8String: logMessage] isEqualToString:@"Complete"])
						{
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
			}
		}

		NS_HANDLER
			NSLog(@"Exception while checking logs: %@", [localException description]);
		NS_ENDHANDLER
		
		if( locked)
			[context unlock];
	}
}

@end
