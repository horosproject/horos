/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "LogManager.h"
#import "browserController.h"
#import "DicomDatabase.h"
#import "DICOMToNSString.h"
#import "DicomFile.h"
#import "N2Debug.h"
#import "Notifications.h"

static LogManager *currentLogManager = nil;

@implementation LogManager

+ (id) currentLogManager
{
	if (!currentLogManager)
		currentLogManager = [[LogManager alloc] init];
	return currentLogManager;
}

- (id) init
{
	if (self = [super init])
	{
		_currentLogs = [[NSMutableDictionary alloc] init];
        
//        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SingleProcessMultiThreadedListener"] == NO)
//            _timer = [[NSTimer scheduledTimerWithTimeInterval: 5 target:self selector:@selector(checkLogs:) userInfo:nil repeats:YES] retain];
	}
	return self;
}

- (void) resetLogs
{
    [independentContext lock];
    @try
    {
        [independentContext save: nil];
        [independentContext release];
        independentContext = nil;
        
        currentDatabase = nil;
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
    [independentContext unlock];
    
	DicomDatabase* db = [[BrowserController currentBrowser] database];
	[db lock];
	
	[_currentLogs removeAllObjects];
	
	@try {
		NSArray* array = [db objectsForEntity:db.logEntryEntity predicate:[NSPredicate predicateWithFormat: @"message like[cd] %@", @"In Progress"]];
		for (NSManagedObject* o in array)
			[o setValue: @"Incomplete" forKey:@"message"];
	} @catch (NSException* e) {
        N2LogException(e);
	} @finally {
        [db unlock];
    }
}

- (void) dealloc
{
	[_currentLogs release];
//	[_timer invalidate];
//	[_timer release];
	[super dealloc];
}

- (NSString *) logFolder
{
	NSString *path =  [NSString stringWithUTF8String: [[[BrowserController currentBrowser] database] tempDirPathC]];
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDir;
	if (!([manager fileExistsAtPath:path isDirectory:&isDir] && isDir))
	{
		[manager createDirectoryAtPath:path attributes:nil];
	}
	return path;
}

- (void) addLogLine: (NSDictionary*) dict
{
    if( [[BrowserController currentBrowser] isNetworkLogsActive] && [[[BrowserController currentBrowser] database] isLocal])
	{
        if( currentDatabase == nil || currentDatabase != [[BrowserController currentBrowser] database])
        {
            currentDatabase = [[BrowserController currentBrowser] database];
            
            [independentContext lock];
            @try
            {
                [independentContext save: nil];
                [independentContext release];
                independentContext = nil;
            }
            @catch ( NSException *e) {
                N2LogException( e);
            }
            [independentContext unlock];
        }
        
        if( independentContext == nil)
            independentContext = [[[[BrowserController currentBrowser] database] independentContext] retain];
        
		if( independentContext == nil)
			return;
		
        [independentContext lock];
        @try
        {
            if( [[dict valueForKey: @"logMessage"] isEqualToString:@"In Progress"] || [[dict valueForKey: @"logMessage"] isEqualToString:@"Complete"] || [[dict valueForKey: @"logMessage"] isEqualToString:@"Incomplete"])
            {
                NSString *uid = [dict valueForKey: @"logUID"];
                
                NSManagedObject *logEntry = nil;
                
                if( [_currentLogs objectForKey:uid])
                    logEntry = [independentContext objectWithID: [_currentLogs objectForKey:uid]];
                
                if (logEntry == nil)
                {
                    logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext: independentContext];
                    
                    [logEntry setValue:[dict valueForKey: @"logStartTime"]  forKey:@"startTime"];
                    [logEntry setValue:[dict valueForKey: @"logType"] forKey:@"type"];
                    [logEntry setValue:[dict valueForKey: @"logCallingAET"] forKey:@"originName"];
                    [logEntry setValue:[dict valueForKey: @"logCalledAET"] forKey:@"destinationName"];
                    [logEntry setValue:[dict valueForKey: @"logPatientName"] forKey:@"patientName"];
                    [logEntry setValue:[dict valueForKey: @"logStudyDescription"] forKey:@"studyName"];
                    
                    [independentContext lock];
                    @try
                    {
                        [independentContext save: nil]; // To have a valid objectID
                    }
                    @catch ( NSException *e) {
                        N2LogException( e);
                    }
                    [independentContext unlock];
                    
                    [_currentLogs setObject: logEntry.objectID forKey:uid];
                }
                
                if( logEntry != nil && [logEntry isDeleted] == NO)
                {
                    [logEntry setValue:[dict valueForKey: @"logMessage"] forKey:@"message"];
                    [logEntry setValue:[NSNumber numberWithInt: [[dict valueForKey: @"logNumberTotal"] intValue]] forKey:@"numberImages"];
                    [logEntry setValue:[NSNumber numberWithInt: [[dict valueForKey: @"logNumberReceived"] intValue]] forKey:@"numberSent"];
                    [logEntry setValue:[NSNumber numberWithInt: [[dict valueForKey: @"logNumberError"] intValue]] forKey:@"numberError"];
                    
                    NSDate *logEndTime = [dict valueForKey: @"logEndTime"];
                    
                    if( [[dict valueForKey: @"logMessage"] isEqualToString:@"Complete"] || [[dict valueForKey: @"logMessage"] isEqualToString:@"Incomplete"])
                    {
                        if( logEndTime == 0)
                            logEndTime = [NSDate date];
                        
                        [_currentLogs removeObjectForKey: uid];
                    }
                    
                    if( logEndTime != 0)
                        [logEntry setValue: logEndTime forKey:@"endTime"];
                }
                
                if( [NSDate timeIntervalSinceReferenceDate] - lastSave > 10 || [[dict valueForKey: @"logMessage"] isEqualToString:@"Complete"])
                {
                    [independentContext save: nil];
                    lastSave = [NSDate timeIntervalSinceReferenceDate];
                }
            }
        }
        @catch ( NSException *e) {
            N2LogException( e);
        }
        [independentContext unlock];
    }
}

//- (void) checkLogs:(NSTimer *)timer
//{
//    if( [[BrowserController currentBrowser] isNetworkLogsActive] && [[[BrowserController currentBrowser] database] isLocal])
//    {
//		char logPatientName[ 1024];
//		char logStudyDescription[ 1024];
//		char logCallingAET[ 1024];
//		char logStartTime[ 1024];
//		char logMessage[ 1024];
//		char logUID[ 1024];
//		char logNumberReceived[ 1024];
//		char logNumberTotal[ 1024];
//		char logEndTime[ 1024];
//		char logType[ 1024];
//		char logEncoding[ 1024];
//
//		logPatientName[ 0] = 0;
//		logStudyDescription[ 0] = 0;
//		logCallingAET[ 0] = 0;
//		logStartTime[ 0] = 0;
//		logMessage[ 0] = 0;
//		logUID[ 0] = 0;
//		logNumberReceived[ 0] = 0;
//		logNumberTotal[ 0] = 0;
//		logEndTime[ 0] = 0;
//		logType[ 0] = 0;
//		logEncoding[ 0] = 0;
//		
//        NSString *logFolder = [self logFolder];
//        NSFileManager *manager = [NSFileManager defaultManager];
//        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath: logFolder];
//        NSString *path;
//        
//        @try
//        {
//            while (path = [enumerator nextObject])
//            {
//                if ([[path pathExtension] isEqualToString: @"log"])
//                {
//                    NSString *file = [logFolder stringByAppendingPathComponent:path];
//                    NSString *newfile = [file stringByAppendingString:@"reading"];
//                    
//                    FILE * pFile;
//                    pFile = fopen ( [file UTF8String], "r");
//                    if( pFile)
//                    {
//                        fclose (pFile);
//                        pFile = nil;
//                        
//                        rename( [file UTF8String], [newfile UTF8String]);
//                        remove( [file UTF8String]);
//                        
//                        pFile = fopen ( [newfile UTF8String], "r");
//                        if( pFile)
//                        {
//                            char data[ 4096];
//                            
//                            fread( data, 4096, 1 ,pFile);
//                            
//                            char *curData = data;
//                            
//                            if(curData) strcpy( logPatientName, strsep( &curData, "\r"));
//                            if(curData) strcpy( logStudyDescription, strsep( &curData, "\r"));
//                            if(curData) strcpy( logCallingAET, strsep( &curData, "\r"));
//                            if(curData) strcpy( logStartTime, strsep( &curData, "\r"));
//                            if(curData) strcpy( logMessage, strsep( &curData, "\r"));
//                            if(curData) strcpy( logUID, strsep( &curData, "\r"));
//                            if(curData) strcpy( logNumberReceived, strsep( &curData, "\r"));
//                            if(curData) strcpy( logEndTime, strsep( &curData, "\r"));
//                            if(curData) strcpy( logType, strsep( &curData, "\r"));
//                            if(curData) strcpy( logEncoding, strsep( &curData, "\r"));
//                            if(curData) strcpy( logNumberTotal, strsep( &curData, "\r"));
//                            
//                            fclose (pFile);
//                            remove( [newfile UTF8String]);
//                            
//                            // Encoding
//                            NSStringEncoding encoding[ 10];
//                            for( int i = 0; i < 10; i++) encoding[ i] = 0;
//                            encoding[ 0] = NSISOLatin1StringEncoding;
//                            
//                            NSArray	*c = [[NSString stringWithCString: logEncoding] componentsSeparatedByString:@"\\"];
//                            
//                            if( [c count] < 10)
//                            {
//                                for( int i = 0; i < [c count]; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c objectAtIndex: i]];
//                            }
//                            
//                            [self addLogLine: [NSDictionary dictionaryWithObjectsAndKeys:   [NSString stringWithUTF8String: logMessage], @"logMessage",
//                                                                                            [NSString stringWithUTF8String: logType], @"logType",
//                                                                                            [NSString stringWithUTF8String: logCallingAET], @"logCallingAET",
//                                                                                            [NSString stringWithUTF8String: logUID], @"logUID",
//                                                                                            [NSString stringWithUTF8String: logStartTime], @"logStartTime",
//                                                                                            [DicomFile stringWithBytes: (char*) logPatientName encodings: encoding], @"logPatientName",
//                                                                                            [DicomFile stringWithBytes: (char*) logStudyDescription encodings: encoding], @"logStudyDescription",
//                                                                                            [NSString stringWithUTF8String: logNumberTotal], @"logNumberTotal",
//                                                                                            [NSString stringWithUTF8String: logNumberReceived], @"logNumberReceived",
//                                                                                            [NSString stringWithUTF8String: logEndTime], @"logEndTime",
//                                                                                            nil]];
//                        }
//                        else NSLog(@"***** Unable to load a log message: %@", newfile);
//                    }
//                    else NSLog(@"----- log file not readable, will try later");
//                }
//            }
//        }
//        @catch( NSException *localException)
//        {
//            NSLog(@"Exception while checking logs: %@", [localException description]);
//        }
//	}
//}
@end
