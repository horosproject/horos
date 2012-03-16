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

#import "DicomDatabase+Clean.h"
#import "N2Debug.h"
#import "AppController.h"
#import "ThreadsManager.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "BrowserController.h"
#import "Notifications.h"
#import "NSThread+N2.h"


@interface DicomDatabase (Private)

-(NSRecursiveLock*)cleanLock;

+(void)_syncCleanTimer;

@end

@implementation DicomDatabase (Clean)

-(void)initClean {
	if (!self.mainDatabase) {
        _cleanLock = [[NSRecursiveLock alloc] init];
    } else {
        _cleanLock = [[self.mainDatabase cleanLock] retain];
    }
	[DicomDatabase _syncCleanTimer];
}

-(void)deallocClean {
	NSRecursiveLock* temp;
	
    if (!self.mainDatabase) {
        temp = _cleanLock;
        [temp lock]; // if currently cleaning, wait until finished
        _cleanLock = nil;
        [temp unlock];
        [temp release];
    } else {
        [_cleanLock release];
    }
}

-(NSRecursiveLock*)cleanLock {
    return _cleanLock;
}

+(void)_syncCleanTimer {
	static NSTimer* cleanTimer = nil;
	
	if (cleanTimer)
		return;
	
	cleanTimer = [[NSTimer timerWithTimeInterval:15*60+2.5 target:self selector:@selector(_cleanTimerCallback:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop mainRunLoop] addTimer:cleanTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop mainRunLoop] addTimer:cleanTimer forMode:NSDefaultRunLoopMode];
}

+(void)_cleanTimerCallback:(NSTimer*)timer {
	for (DicomDatabase* dbi in [self allDatabases])
		if (dbi.isLocal)
			[dbi initiateCleanUnlessAlreadyCleaning];
}

-(void)initiateCleanUnlessAlreadyCleaning {
	if ([_cleanLock tryLock])
		@try {
			[self performSelectorInBackground:@selector(_cleanThread) withObject:nil];
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		} @finally {
			[_cleanLock unlock];
		}
	else NSLog(@"Warning: couldn't initiate clean");
}

-(void)_cleanThread {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	@try {
		NSThread* thread = [NSThread currentThread];
		thread.name = NSLocalizedString(@"Cleaning...", nil);
		[self.independentDatabase cleanOldStuff];
	} @catch (NSException * e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(void)cleanOldStuff {
    if (self.isReadOnly)
        return;
	if (!self.isLocal) return;
	if ([AppController.sharedAppController isSessionInactive]) return;
//	if ([NSDate timeIntervalSinceReferenceDate] - gLastActivity < 60*10) return; // TODO: this
	
	[_cleanLock lock];
	@try {
		NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
		
		// Log cleaning
		if ([self tryLock])
			@try {
				NSDate					*producedDate = [[NSDate date] addTimeInterval: -[defaults integerForKey:@"LOGCLEANINGDAYS"]*60*60*24];
				NSPredicate				*predicate = [NSPredicate predicateWithFormat: @"startTime <= CAST(%lf, \"NSDate\")", [producedDate timeIntervalSinceReferenceDate]];
				for (id log in [self objectsForEntity:self.logEntryEntity predicate:predicate])
					[self.managedObjectContext deleteObject:log];
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			} @finally {
				[self unlock];
			}
		
		/*// reduce memory footprint for CoreData - ONLY FOR SERVER MODE
		if( gLastCoreDataReset == 0)
			gLastCoreDataReset = [NSDate timeIntervalSinceReferenceDate];
		if( [NSDate timeIntervalSinceReferenceDate] - gLastCoreDataReset > 60*60)
			if ([self tryLock])
				@try {
					if(newFilesInIncoming == NO && [SendController sendControllerObjects] == 0 && [[ThreadsManager defaultManager] threadsCount] == 0 && [AppController numberOfSubOsiriXProcesses] == 0)
						if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"]) {
							gLastCoreDataReset = [NSDate timeIntervalSinceReferenceDate];
							[self reduceCoreDataFootPrint];
						}
				} @catch (NSException* e) {
					N2LogExceptionWithStackTrace(e);
				} @finally {
					[self unlock];
				}*/
		
		// Build thumbnails
		//[self buildAllThumbnails: self];
		
		if ([defaults boolForKey:@"AUTOCLEANINGDATE"] && ([defaults boolForKey:@"AUTOCLEANINGDATEPRODUCED"] || [defaults boolForKey:@"AUTOCLEANINGDATEOPENED"])) {
			if ([self tryLock])
				@try {
					NSError				*error = nil;
					NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
					//NSPredicate			*predicate = [NSPredicate predicateWithValue:YES];
					NSArray				*studiesArray;
					NSDate				*now = [NSDate date];
					NSDate				*producedDate = [now addTimeInterval: -[[defaults stringForKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"] intValue]*60*60*24];
					NSDate				*openedDate = [now addTimeInterval: -[[defaults stringForKey:@"AUTOCLEANINGDATEOPENEDDAYS"] intValue]*60*60*24];
					NSMutableArray		*toBeRemoved = [NSMutableArray array];
//					NSManagedObjectContext *context = self.managedObjectContext;
					BOOL				dontDeleteStudiesWithComments = [[NSUserDefaults standardUserDefaults] boolForKey: @"dontDeleteStudiesWithComments"];
					
					@try {
						studiesArray = [[self objectsForEntity:self.studyEntity] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease]]];
						for (NSInteger i = 0; i < [studiesArray count]; i++) {
							NSString	*patientID = [[studiesArray objectAtIndex: i] valueForKey:@"patientID"];
							NSDate		*studyDate = [[studiesArray objectAtIndex: i] valueForKey:@"date"];
							NSDate		*openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"];
							
							if( openedStudyDate == nil) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
							
							int to, from = i;
							
							while( i < [studiesArray count]-1 && [patientID isEqualToString:[[studiesArray objectAtIndex: i+1] valueForKey:@"patientID"]] == YES)
							{
								i++;
								studyDate = [studyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"date"]];
								if( [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"]) openedStudyDate = [openedStudyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"]];
								else openedStudyDate = [openedStudyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"]];
							}
							to = i;
							
							BOOL dateProduced = YES, dateOpened = YES;
							
							if( [defaults boolForKey: @"AUTOCLEANINGDATEPRODUCED"])
								dateProduced = [producedDate compare: studyDate] == NSOrderedDescending;
							
							if( [defaults boolForKey: @"AUTOCLEANINGDATEOPENED"])
							{
								if( openedStudyDate == nil) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
								
								dateOpened = [openedDate compare: openedStudyDate] == NSOrderedDescending;
							}
							
							if(  dateProduced == YES && dateOpened == YES)
							{
								for( int x = from; x <= to; x++)
								{
									if( [toBeRemoved containsObject:[studiesArray objectAtIndex: x]] == NO && [[[studiesArray objectAtIndex: x] valueForKey:@"lockedStudy"] boolValue] == NO)
									{
										if( dontDeleteStudiesWithComments)
										{
											DicomStudy *dy = [studiesArray objectAtIndex: x];
											
											NSString *str = @"";
											
											if( [dy valueForKey: @"comment"])
												str = [str stringByAppendingString: [dy valueForKey: @"comment"]];
											if( [dy valueForKey: @"comment2"])
												str = [str stringByAppendingString: [dy valueForKey: @"comment2"]];
											if( [dy valueForKey: @"comment3"])
												str = [str stringByAppendingString: [dy valueForKey: @"comment3"]];
											if( [dy valueForKey: @"comment4"])
												str = [str stringByAppendingString: [dy valueForKey: @"comment4"]];
											
											
											if( str == nil || [str isEqualToString: @""])
												[toBeRemoved addObject: [studiesArray objectAtIndex: x]];
										}
										else
											[toBeRemoved addObject: [studiesArray objectAtIndex: x]];
									}
								}
							}
						}
						
						for ( int i = 0; i < [toBeRemoved count]; i++) // Check if studies are in an album or added this week.  If so don't autoclean that study from the database (DDP: 051108).
						{
							if ( [[[toBeRemoved objectAtIndex: i] valueForKey: @"albums"] count] > 0 ||
								[[[toBeRemoved objectAtIndex: i] valueForKey: @"dateAdded"] timeIntervalSinceNow] > -60*60*7*24.0)  // within 7 days
							{
								[toBeRemoved removeObjectAtIndex: i];
								i--;
							}
						}
						
						if( [defaults boolForKey: @"AUTOCLEANINGCOMMENTS"])
						{
							for ( int i = 0; i < [toBeRemoved count]; i++)
							{
								NSString *comment = [[toBeRemoved objectAtIndex: i] valueForKey: @"comment"];
								
								if( comment == nil) comment = @"";
								
								if ([comment rangeOfString:[defaults stringForKey: @"AUTOCLEANINGCOMMENTSTEXT"] options:NSCaseInsensitiveSearch].location == NSNotFound)
								{
									if( [defaults integerForKey: @"AUTOCLEANINGDONTCONTAIN"] == 0)
									{
										[toBeRemoved removeObjectAtIndex: i];
										i--;
									}
								}
								else
								{
									if( [defaults integerForKey: @"AUTOCLEANINGDONTCONTAIN"] == 1)
									{
										[toBeRemoved removeObjectAtIndex: i];
										i--;
									}
								}
							}
						}
					}
					@catch (NSException * e)
					{
                        N2LogExceptionWithStackTrace(e);
					}
					
					if( [toBeRemoved count] > 0)
					{
						NSLog(@"Will delete: %d studies", [toBeRemoved count]);
						
//						Wait *wait = [[Wait alloc] initWithString: NSLocalizedString(@"Database Auto-Cleaning...", nil)];
//						[wait showWindow:self];
//						[wait setCancel: YES];
//						[[wait progress] setMaxValue:[toBeRemoved count]];
						
						@try
						{
							if ([defaults boolForKey:@"AUTOCLEANINGDELETEORIGINAL"]) {
								NSMutableArray* nonLocalImagesPath = [NSMutableArray array];
								
								for (NSManagedObject* curObj in toBeRemoved) {
									if ([[curObj valueForKey:@"type"] isEqualToString:@"Study"])
										for (DicomSeries* series in [[((DicomStudy*)curObj) series] allObjects])
											[nonLocalImagesPath addObjectsFromArray:[[series.images.allObjects filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"]];
									else NSLog(@"Uh? Autocleaning, object strange...");
								}
								
								for (NSString* path in nonLocalImagesPath) {
									[NSFileManager.defaultManager removeItemAtPath:path error:nil];
									if ([path.pathExtension isEqualToString:@"hdr"]) // ANALYZE -> DELETE IMG
										[NSFileManager.defaultManager removeItemAtPath:[path.stringByDeletingPathExtension stringByAppendingPathExtension:@"img"] error:NULL];
								}
							}
							
							for (id obj in toBeRemoved) {
								[self.managedObjectContext deleteObject:obj];
//								[wait incrementBy:1];
//								if( [wait aborted]) break;
							}
							
							[self save:NULL];
							
//							[self outlineViewRefresh];
						} @catch (NSException* e) {
                            N2LogExceptionWithStackTrace(e);
						}
//						[wait close];
//						[wait release];
						
						// refresh database
						[NSNotificationCenter.defaultCenter postNotificationName:_O2AddToDBAnywayNotification object:self userInfo:nil];
						[NSNotificationCenter.defaultCenter postNotificationName:_O2AddToDBAnywayCompleteNotification object:self userInfo:nil];
						[NSNotificationCenter.defaultCenter postNotificationName:OsirixAddToDBNotification object:self userInfo:nil];
						[NSNotificationCenter.defaultCenter postNotificationName:OsirixAddToDBCompleteNotification object:self userInfo:nil];						
					}
					
				} @catch (NSException* e) {
					N2LogExceptionWithStackTrace(e);
				} @finally {
					[self unlock];
				}
		}
		
        [self save];
        
		[self cleanForFreeSpace];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_cleanLock unlock];
	}
	
}

static BOOL _showingCleanForFreeSpaceWarning = NO;

-(void)_cleanForFreeSpaceWarning {
    if (!_showingCleanForFreeSpaceWarning) {
        _showingCleanForFreeSpaceWarning = YES;
        NSBeginAlertSheet(NSLocalizedString(@"Warning", nil), nil, nil, nil, nil, [self retain], @selector(_cleanForFreeSpaceWarningDidEnd:returnCode:contextInfo:), nil, nil, NSLocalizedString(@"Your hard disk is FULL! Major risks of failure! Clean your database!!", nil));
    }
}

-(void)_cleanForFreeSpaceWarningDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
    _showingCleanForFreeSpaceWarning = NO;
    [self release];
}

-(void)cleanForFreeSpace {
	if (self.isReadOnly)
        return;
    
    [_cleanLock lock];
    
    NSThread* thread = [NSThread currentThread];
    [thread enterOperationIgnoringLowerLevels];
    thread.status = NSLocalizedString(@"Cleaning database...", nil);
    
	@try {
        
        if( [NSUserDefaults.standardUserDefaults boolForKey:@"AUTOCLEANINGSPACE"])
		{
            NSDictionary* fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
            if (![fsattrs objectForKey:NSFileSystemSize]) {
                NSLog(@"Error: database cleaning mechanism couldn't obtain filesystem size information for %@", self.dataBaseDirPath);
                return;
            }
            
			float acss = [[NSUserDefaults.standardUserDefaults stringForKey:@"AUTOCLEANINGSPACESIZE"] floatValue];
			unsigned long long freeMemoryRequested = 0;
			if (acss < 0) { // Percentages !
                unsigned long long diskSizeMB = [[fsattrs objectForKey:NSFileSystemSize] unsignedLongLongValue]/1024/1024;
				freeMemoryRequested = -acss/100*diskSizeMB;
			} else freeMemoryRequested = acss;
			
			[self cleanForFreeSpaceMB:freeMemoryRequested];
		}
		
		// warn user if less than 1% / 300MB available
		if ([self isFileSystemFreeSizeLimitReached])
            [self performSelectorOnMainThread:@selector(_cleanForFreeSpaceWarning) withObject:nil waitUntilDone:NO];
		
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
        [thread exitOperation];
		[_cleanLock unlock];
	}
}

-(void)cleanForFreeSpaceMB:(NSInteger)freeMemoryRequested {
	if (self.isReadOnly)
        return;

	[_cleanLock lock];
    
    NSThread* thread = [NSThread currentThread];
    [thread enterOperation];
    
	@try {
		NSDictionary* fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
		if ([fsattrs objectForKey:NSFileSystemFreeSize] == nil) {
			NSLog(@"Error: database cleaning mechanism couldn't obtain filesystem space information for %@", self.dataBaseDirPath);
			return;
		}
		
		unsigned long long free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue]/1024/1024; // megabytes

/*		if (_lastFreeSpace != free && ([NSDate timeIntervalSinceReferenceDate] - _lastFreeSpaceLogTime) > 60*10) { // not more often than every ten minutes, log about the disk's free space
			_lastFreeSpace = free;
			_lastFreeSpaceLogTime = [NSDate timeIntervalSinceReferenceDate];
			NSLog(@"Info: database free space is %ld MB", (long)free);
		}*/
		
		if (free >= freeMemoryRequested)
			return;
		
		NSLog(@"Info: cleaning for space (%lld MB available, %lld MB requested)", free, (unsigned long long)freeMemoryRequested);
		
        unsigned long long initialDelta = freeMemoryRequested - free;
        
        NSMutableArray* studies = [NSMutableArray array];
        NSMutableArray* studiesDates = [NSMutableArray array];
        
        BOOL flagDoNotDeleteIfComments = [[NSUserDefaults standardUserDefaults] boolForKey:@"dontDeleteStudiesWithComments"];
        NSInteger autocleanSpaceMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutocleanSpaceMode"] intValue];
        
        for (DicomStudy* study in [self objectsForEntity:self.studyEntity]) {
            // if study is locked, do not delete it
            if ([study.lockedStudy boolValue])
                continue;
            // if the user told us not to delete studies with comments and there are comments, do not delete it
            if (flagDoNotDeleteIfComments)
                if (study.comment.length || study.comment2.length || study.comment3.length || study.comment4.length)
                    continue;
            
            // study can be deleted
            NSDate* d = nil; // determine the delete priority date
            switch (autocleanSpaceMode) {
                case 0: { // oldest Studies
                    d = study.date;
                } break;
                case 1: { // oldest unopened
                    if (study.dateOpened)
                        d = study.dateOpened;
                    else
                        if (study.dateAdded)
                            d = study.dateAdded;
                        else d = study.date;
                } break;
                case 2: { // least recently added
                    if (study.dateAdded)
                        d = study.dateAdded;
                    else d = study.date;
                } break;
            }
            
            [studiesDates addObject:[NSArray arrayWithObjects: study, d, nil]];   
        }
        
        // sort studiesDates by date
        [studiesDates sortUsingComparator: ^(id a, id b) {
            return [[a objectAtIndex:1] compare:[b objectAtIndex:1]];
        }];
        
        NSString* dataBaseDirPathSlashed = self.dataBaseDirPath;
        if (![dataBaseDirPathSlashed hasSuffix:@"/"])
            dataBaseDirPathSlashed = [dataBaseDirPathSlashed stringByAppendingString:@"/"];
        
        BOOL flagDeleteLinkedImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOCLEANINGDELETEORIGINAL"];
        
        for (NSArray* sd in studiesDates) {
            { CGFloat a = initialDelta, b = freeMemoryRequested, f = free; [NSThread currentThread].progress = (a-(b-f))/a; }
            
            DicomStudy* study = [sd objectAtIndex:0];
            NSLog(@"Info: study [%@ - %@ - %@] is being deleted for space (added %@, last opened %@)", study.name, study.studyName, study.date, study.dateAdded, study.dateOpened);
            
            // list images to be deleted
            NSMutableArray* imagesToDelete = [NSMutableArray array];
            for (DicomSeries* series in [[study series] allObjects])
                for (DicomImage* image in series.images.allObjects)
                    if (flagDeleteLinkedImages || [image.completePath hasPrefix:dataBaseDirPathSlashed])
                        [imagesToDelete addObject:image];
            
            // delete image files
            for (DicomImage* image in imagesToDelete) {
                NSString* path = image.completePath;
                unlink(path.fileSystemRepresentation); // faster than [NSFileManager.defaultManager removeItemAtPath:path error:NULL];
                if ([path.pathExtension isEqualToString:@"hdr"]) // ANALYZE -> DELETE IMG
                    [NSFileManager.defaultManager removeItemAtPath:[path.stringByDeletingPathExtension stringByAppendingPathExtension:@"img"] error:NULL];
            }
            
            // delete managed objects: images, series, studies
            
            for (DicomSeries* series in [[study series] allObjects]) {
                @try {
                    for (DicomImage* image in series.images.allObjects)
                        @try {
                            [self.managedObjectContext deleteObject:image];
                        } @catch (...) { }
                } @catch (...) { }
                @try {
                    [self.managedObjectContext deleteObject:series];
                } @catch (...) { }
            } @try {
                [self.managedObjectContext deleteObject:study];
            } @catch (...) { }
            
            // did we free up enough space?
            
            NSDictionary* fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
            free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue]/1024/1024;
            if (free >= freeMemoryRequested) // if so, stop deleting studies
                break;
        }
        
		NSLog(@"Info: done cleaning for space, %lld MB are free", free);
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [thread exitOperation];
        [_cleanLock unlock];
    }
}

@end
