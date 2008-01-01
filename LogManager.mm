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
  
  See http://www.osirix-viewer.com/copyright.html for details.

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

- (void) resetLogs
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
	
	[context retain];
	[context lock];
	
	[_currentLogs removeAllObjects];
	
	[context unlock];
	[context release];
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
		
		if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour]) return;
		
//		// Tests
//		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
//		[dbRequest setEntity: [[[BrowserController currentBrowser].managedObjectModel entitiesByName] objectForKey:@"LogEntry"]];
//		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
//		NSError	*error = 0L;
//		NSArray *l = [context executeFetchRequest:dbRequest error:&error];
//		
//		NSLog(@"%@", l);
//		
//		//
		
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
		char logType[ 1024];

		logPatientName[ 0] = 0;
		logStudyDescription[ 0] = 0;
		logCallingAET[ 0] = 0;
		logStartTime[ 0] = 0;
		logMessage[ 0] = 0;
		logUID[ 0] = 0;
		logNumberReceived[ 0] = 0;
		logEndTime[ 0] = 0;
		logType[ 0] = 0;
		
		[context retain];
		[context lock];
		
		NS_DURING
		while (path = [enumerator nextObject]){
			if ([[path pathExtension] isEqualToString: @"log"])
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
					if(curData) strcpy( logType, strsep( &curData, "\r"));
					
					fclose (pFile);
					remove( [newfile UTF8String]);
					
					if( [[NSString stringWithUTF8String: logMessage] isEqualToString:@"In Progress"] || [[NSString stringWithUTF8String: logMessage] isEqualToString:@"Complete"])
					{
						if( [[NSString stringWithUTF8String: logType] isEqualToString:@"Move"])
						{
							id logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
								
							[logEntry setValue:[NSDate dateWithTimeIntervalSince1970: [[NSString stringWithUTF8String: logStartTime] intValue]]  forKey:@"startTime"];
							[logEntry setValue:[NSString stringWithUTF8String: logType] forKey:@"type"];
							[logEntry setValue:[NSString stringWithUTF8String: logCallingAET] forKey:@"originName"];
							[logEntry setValue:[NSString stringWithUTF8String: logPatientName] forKey:@"patientName"];
							[logEntry setValue:[NSString stringWithUTF8String: logStudyDescription] forKey:@"studyName"];
							[logEntry setValue:[NSNumber numberWithInt: [[NSString stringWithUTF8String: logNumberReceived] intValue]] forKey:@"numberImages"];
							[logEntry setValue:[NSNumber numberWithInt: [[NSString stringWithUTF8String: logNumberReceived] intValue]] forKey:@"numberSent"];
							[logEntry setValue:0 forKey:@"numberError"];
							[logEntry setValue:[NSDate dateWithTimeIntervalSince1970: [[NSString stringWithUTF8String: logEndTime] intValue]] forKey:@"endTime"];
							[logEntry setValue:[NSString stringWithUTF8String: logMessage] forKey:@"message"];
						}
						else
						{					
							NSString *uid = [NSString stringWithUTF8String: logUID];
							id logEntry = [_currentLogs objectForKey:uid];
							if (logEntry == nil)
							{
								logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
								
								[logEntry setValue:[NSDate dateWithTimeIntervalSince1970: [[NSString stringWithUTF8String: logStartTime] intValue]]  forKey:@"startTime"];
								[logEntry setValue:[NSString stringWithUTF8String: logType] forKey:@"type"];
								[logEntry setValue:[NSString stringWithUTF8String: logCallingAET] forKey:@"originName"];
								[logEntry setValue:[NSString stringWithUTF8String: logPatientName] forKey:@"patientName"];
								[logEntry setValue:[NSString stringWithUTF8String: logStudyDescription] forKey:@"studyName"];
								[_currentLogs setObject:logEntry forKey:uid];
							}
							else if( [logEntry isDeleted] == NO)
							{
								[logEntry setValue:[NSString stringWithUTF8String: logMessage] forKey:@"message"];
								[logEntry setValue:[NSNumber numberWithInt: [[NSString stringWithUTF8String: logNumberReceived] intValue]] forKey:@"numberImages"];
								[logEntry setValue:[NSNumber numberWithInt: [[NSString stringWithUTF8String: logNumberReceived] intValue]] forKey:@"numberSent"];
								[logEntry setValue:0 forKey:@"numberError"];
								[logEntry setValue:[NSDate dateWithTimeIntervalSince1970: [[NSString stringWithUTF8String: logEndTime] intValue]] forKey:@"endTime"];
								
								if( [[NSString stringWithUTF8String: logMessage] isEqualToString:@"Complete"])
								{
									NSLog(@"LogManager transfer Complete");
									[_currentLogs removeObjectForKey: uid];
								}
							}
						}
					}
					else NSLog(@"Unknown log message type");
				}
			}
		}

		NS_HANDLER
			NSLog(@"Exception while checking logs: %@", [localException description]);
		NS_ENDHANDLER
		
		[context unlock];
		[context release];
	}
}

@end
