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
	}
	return self;
}

- (void) resetLogs
{
	DicomDatabase* db = [[BrowserController currentBrowser] database];
	
    @synchronized (self)
    {
        for( NSString *key in _currentLogs)
        {
            NSManagedObject *o = [_currentLogs objectForKey: key];
            [o.managedObjectContext save: nil];
        }
        
        [_currentLogs removeAllObjects];
	}
    
	@try {
		NSArray* array = [db objectsForEntity:db.logEntryEntity predicate:[NSPredicate predicateWithFormat: @"message like[cd] %@", @"In Progress"]];
		for (NSManagedObject* o in array)
			[o setValue: @"Incomplete" forKey:@"message"];
	} @catch (NSException* e) {
        N2LogException(e);
	} @finally {
    }
}

- (void) dealloc
{
	[_currentLogs release];
	[super dealloc];
}

- (void) addLogLine: (NSDictionary*) dict
{
    if( [[BrowserController currentBrowser] isNetworkLogsActive] && [[[BrowserController currentBrowser] database] isLocal])
	{
        @synchronized (self)
        {
            @try
            {
                if( [[dict valueForKey: @"logMessage"] isEqualToString:@"In Progress"] || [[dict valueForKey: @"logMessage"] isEqualToString:@"Complete"] || [[dict valueForKey: @"logMessage"] isEqualToString:@"Incomplete"])
                {
                    NSString *uid = [dict valueForKey: @"logUID"];
                    
                    NSManagedObject *logEntry = nil;
                    
                    if( [_currentLogs objectForKey:uid])
                        logEntry = [_currentLogs objectForKey:uid];
                    
                    if (logEntry == nil)
                    {
                        logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext: [[[BrowserController currentBrowser] database] independentContext]];
                        
                        [logEntry setValue:[dict valueForKey: @"logStartTime"]  forKey:@"startTime"];
                        [logEntry setValue:[dict valueForKey: @"logType"] forKey:@"type"];
                        [logEntry setValue:[dict valueForKey: @"logCallingAET"] forKey:@"originName"];
                        [logEntry setValue:[dict valueForKey: @"logCalledAET"] forKey:@"destinationName"];
                        [logEntry setValue:[dict valueForKey: @"logPatientName"] forKey:@"patientName"];
                        [logEntry setValue:[dict valueForKey: @"logStudyDescription"] forKey:@"studyName"];
                        
                        [_currentLogs setObject: logEntry forKey:uid];
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
                        @try
                        {
                            [logEntry.managedObjectContext save: nil];
                        }
                        @catch ( NSException *e) {
                            N2LogException( e);
                        }
                        
                        lastSave = [NSDate timeIntervalSinceReferenceDate];
                    }
                }
            }
            @catch ( NSException *e) {
                N2LogException( e);
            }
        }
    }
}
@end
