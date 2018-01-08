/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "LogManager.h"
#import "BrowserController.h"
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
        for( NSString *uid in _currentLogs)
            [self updateLogDatabase: [[_currentLogs objectForKey: uid] objectForKey: @"dict"] objectID: [[_currentLogs objectForKey: uid] objectForKey: @"objectID"]];
        
        [_currentLogs removeAllObjects];
	}
    
	@try {
		NSArray* array = [db objectsForEntity:db.logEntryEntity predicate:[NSPredicate predicateWithFormat: @"message like[cd] %@", @"In Progress"]];
		for (NSManagedObject* o in array)
			[o setValue: @"Incomplete" forKey:@"message"];
	} @catch (NSException* e) {
        N2LogException(e);
	}
}

- (void) dealloc
{
	[_currentLogs release];
	[super dealloc];
}

- (BOOL) updateLogDatabase: (NSDictionary*) dict objectID: (NSManagedObjectID*) objectID
{
    BOOL complete = NO;
    
    @try {
        NSManagedObject *logEntry = nil;
        
        if( objectID)
        {
            if( [NSThread isMainThread])
                logEntry = [[[BrowserController currentBrowser] database] objectWithID: objectID];
            else
                logEntry = [[[[BrowserController currentBrowser] database] independentContext] objectWithID: objectID];
        }
        
        if( logEntry)
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
                
                complete = YES;
            }
            
            if( logEndTime != 0)
                [logEntry setValue: logEndTime forKey:@"endTime"];
            
            @try
            {
                [logEntry.managedObjectContext save: nil];
            }
            @catch ( NSException *e)
            {
                N2LogException( e);
            }
        }
    } @catch (NSException* e) {
        N2LogException(e);
	}
    
    return complete;
}

- (void) removeFromCurrentLog: (NSString*) uid
{
    @synchronized( self)
    {
        [_currentLogs removeObjectForKey: uid];
    }
}

- (void) addLogLine: (NSDictionary*) dict
{
    @autoreleasepool
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
                        
                        if( [_currentLogs objectForKey:uid] == nil)
                        {
                            NSManagedObjectContext *context = [NSThread isMainThread] ? [[[BrowserController currentBrowser] database] managedObjectContext] : [[[BrowserController currentBrowser] database] independentContext];
                            
                            NSManagedObject *logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext: context];
                            
                            [logEntry setValue:[dict valueForKey: @"logStartTime"]  forKey:@"startTime"];
                            [logEntry setValue:[dict valueForKey: @"logType"] forKey:@"type"];
                            [logEntry setValue:[dict valueForKey: @"logCallingAET"] forKey:@"originName"];
                            [logEntry setValue:[dict valueForKey: @"logCalledAET"] forKey:@"destinationName"];
                            [logEntry setValue:[dict valueForKey: @"logPatientName"] forKey:@"patientName"];
                            [logEntry setValue:[dict valueForKey: @"logStudyDescription"] forKey:@"studyName"];
                            
                            @try {
                                [logEntry.managedObjectContext save: nil];
                            }
                            @catch ( NSException *e) {
                                N2LogException( e);
                            }
                            
                            [_currentLogs setObject: [NSDictionary dictionaryWithObjectsAndKeys: logEntry.objectID, @"objectID", dict, @"dict", [NSNumber numberWithDouble: [NSDate timeIntervalSinceReferenceDate]], @"lastSave", nil] forKey:uid];
                        }
                        
                        if( [_currentLogs objectForKey:uid])
                        {
                            NSMutableDictionary *previousDict = [[[_currentLogs objectForKey:uid] mutableCopy] autorelease];
                            
                            [previousDict setObject: dict forKey: @"dict"];
                            
                            NSTimeInterval lastSave = [[previousDict objectForKey: @"lastSave"] doubleValue];
                            if( [NSDate timeIntervalSinceReferenceDate] - lastSave > 5 || [[dict valueForKey: @"logMessage"] isEqualToString:@"Complete"])
                            {
                                if( [self updateLogDatabase: [[_currentLogs objectForKey:uid] objectForKey: @"dict"] objectID: [[_currentLogs objectForKey:uid] objectForKey: @"objectID"]])
                                {
                                    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector( removeFromCurrentLog:) object: uid];
                                    [self performSelector: @selector( removeFromCurrentLog:) withObject: uid afterDelay: 5];
                                }
                                
                                [previousDict setObject: [NSNumber numberWithDouble: [NSDate timeIntervalSinceReferenceDate]] forKey: @"lastSave"];
                            }
                            
                            [_currentLogs setObject: previousDict forKey: uid];
                        }
                        else
                            NSLog( @"********** [_currentLogs objectForKey:uid] == nil");
                    }
                }
                @catch ( NSException *e) {
                    N2LogException( e);
                }
            }
        }
    }
}
@end
