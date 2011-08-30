//
//  DicomDatabase+Clean.mm
//  OsiriX
//
//  Created by Alessandro Volz on 19.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase+Clean.h"
#import "N2Debug.h"
#import "AppController.h"
#import "ThreadsManager.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "BrowserController.h"
#import "Notifications.h"


@interface DicomDatabase ()

+(void)_syncCleanTimer;

@end

@implementation DicomDatabase (Clean)

-(void)initClean {
	_cleanLock = [[NSRecursiveLock alloc] init];
	[DicomDatabase _syncCleanTimer];
}

-(void)deallocClean {
	NSRecursiveLock* temp;
	
	temp = _cleanLock;
	[temp lock]; // if currently cleaning, wait until finished
	_cleanLock = nil;
	[temp unlock];
	[temp release];
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
		[self cleanOldStuff];
	} @catch (NSException * e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(void)cleanOldStuff {
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
		
		[self cleanForFreeSpace];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_cleanLock unlock];
	}
	
}

-(void)cleanForFreeSpace {
	[_cleanLock lock];
	@try {
		if( [NSUserDefaults.standardUserDefaults boolForKey:@"AUTOCLEANINGSPACE"])
		{
			unsigned long long freeMemoryRequested = 0;
			NSString* acss = [NSUserDefaults.standardUserDefaults stringForKey:@"AUTOCLEANINGSPACESIZE"];
			
			if( [acss floatValue] < 0) // Percentages !
			{
				NSDictionary *fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
				unsigned long long diskSize = [[fsattrs objectForKey:NSFileSystemSize] unsignedLongLongValue]/1024/1024;

				double percentage = - (float) [acss floatValue] / 100.;
				freeMemoryRequested = diskSize * percentage;
			}
			else freeMemoryRequested = [acss longLongValue];
			
			// if (sender == 0L)	// Received by the NSTimer : have a larger amount of free memory !
				freeMemoryRequested = 1.3*freeMemoryRequested;
			
			[self cleanForFreeSpaceMB:freeMemoryRequested];
		}
		
		// warn user if less than 300 MB available
		NSDictionary* fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
		if( [fsattrs objectForKey:NSFileSystemFreeSize])
			if ([[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue]/1024/1024 < 300)
				[self performSelectorOnMainThread:@selector(_cleanForFreeSpaceWarning) withObject:nil waitUntilDone:NO];
		
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_cleanLock unlock];
	}
}

-(void)cleanForFreeSpaceMB:(NSInteger)freeMemoryRequested {
	[_cleanLock lock];
	@try {
		NSDictionary *fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
		
		unsigned long long free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue]/1024/1024;
		
		if ([fsattrs objectForKey:NSFileSystemFreeSize] == nil) {
			NSLog( @"*** autoCleanDatabaseFreeSpace [fsattrs objectForKey:NSFileSystemFreeSize] == nil ?? : %@", self.dataBaseDirPath);
			return;
		}
		
		if( _lastFreeSpace != free && ([NSDate timeIntervalSinceReferenceDate] - _lastFreeSpaceLogTime) > 60*10) {
			_lastFreeSpace = free;
			_lastFreeSpaceLogTime = [NSDate timeIntervalSinceReferenceDate];
			NSLog(@"HD Free Space: %ld MB", (long)free);
		}
		
		if (free >= freeMemoryRequested)
			return;
		
		NSLog(@"------------------- Limit Reached - Starting autoCleanDatabaseFreeSpace");
		
		if( [NSUserDefaults.standardUserDefaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"] == NO && [NSUserDefaults.standardUserDefaults boolForKey:@"AUTOCLEANINGSPACEOPENED"] == NO)
		{
			NSLog( @"***** WARNING - AUTOCLEANINGSPACE : no options specified !");
		}
		else {
			NSMutableArray* unlockedStudies = nil;
			BOOL dontDeleteStudiesWithComments = [NSUserDefaults.standardUserDefaults boolForKey: @"dontDeleteStudiesWithComments"];
			
			@try
			{
				do
				{
					NSTimeInterval producedInterval = 0;
					NSTimeInterval openedInterval = 0;
					NSManagedObject *oldestStudy = nil, *oldestOpenedStudy = nil;
					
					[self lock];
					@try {
						NSArray* studiesArray = [self objectsForEntity:self.studyEntity];
						
						NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease];
						studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
						
						unlockedStudies = [NSMutableArray arrayWithArray: studiesArray];
						
						for( int i = 0; i < [unlockedStudies count]; i++)
						{
							if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"lockedStudy"] boolValue] == YES)
							{
								[unlockedStudies removeObjectAtIndex: i];
								i--;
							}
							else if( dontDeleteStudiesWithComments)
							{
								DicomStudy *dy = [unlockedStudies objectAtIndex: i];
								
								NSString *str = @"";
								
								if( [dy valueForKey: @"comment"])
									str = [str stringByAppendingString: [dy valueForKey: @"comment"]];
								if( [dy valueForKey: @"comment2"])
									str = [str stringByAppendingString: [dy valueForKey: @"comment2"]];
								if( [dy valueForKey: @"comment3"])
									str = [str stringByAppendingString: [dy valueForKey: @"comment3"]];
								if( [dy valueForKey: @"comment4"])
									str = [str stringByAppendingString: [dy valueForKey: @"comment4"]];
								
								if( str != nil && [str isEqualToString:@""] == NO)
								{
									[unlockedStudies removeObjectAtIndex: i];
									i--;
								}
							}
						}
						
						if( [unlockedStudies count] > 2)
						{
							for( long i = 0; i < [unlockedStudies count]; i++)
							{
								NSString	*patientID = [[unlockedStudies objectAtIndex: i] valueForKey:@"patientID"];
								long		to;
								
								if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"date"] timeIntervalSinceNow] < producedInterval)
								{
									if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"] timeIntervalSinceNow] < -60*60*24)	// 24 hours
									{
										oldestStudy = [unlockedStudies objectAtIndex: i];
										producedInterval = [[oldestStudy valueForKey:@"date"] timeIntervalSinceNow];
									}
								}
								
								NSDate *openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateOpened"];
								if( openedDate == nil) openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"];
								
								if( [openedDate timeIntervalSinceNow] < openedInterval)
								{
									oldestOpenedStudy = [unlockedStudies objectAtIndex: i];
									openedInterval = [openedDate timeIntervalSinceNow];
								}
								
								while( i < [unlockedStudies count]-1 && [patientID isEqualToString:[[unlockedStudies objectAtIndex: i+1] valueForKey:@"patientID"]] == YES)
								{
									i++;
									if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"date"] timeIntervalSinceNow] < producedInterval)
									{
										if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"] timeIntervalSinceNow] < -60*60*24)	// 24 hours
										{
											oldestStudy = [unlockedStudies objectAtIndex: i];
											producedInterval = [[oldestStudy valueForKey:@"date"] timeIntervalSinceNow];
										}
									}
									
									openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateOpened"];
									if( openedDate == nil) openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"];
									
									if( [openedDate timeIntervalSinceNow] < openedInterval)
									{
										oldestOpenedStudy = [unlockedStudies objectAtIndex: i];
										openedInterval = [openedDate timeIntervalSinceNow];
									}
								}
								to = i;
							}
						}
						
						if( [NSUserDefaults.standardUserDefaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"])
						{
							if( oldestStudy)
							{
								NSLog( @"delete oldestStudy: %@", [oldestStudy valueForKey:@"patientUID"]);
								[self.managedObjectContext deleteObject: oldestStudy];
							}
						}
						
						if ( [NSUserDefaults.standardUserDefaults boolForKey:@"AUTOCLEANINGSPACEOPENED"])
						{
							if( oldestOpenedStudy)
							{
								NSLog( @"delete oldestOpenedStudy: %@", [oldestOpenedStudy valueForKey:@"patientUID"]);
								[self.managedObjectContext deleteObject: oldestOpenedStudy];
							}
						}
						
						[self save:NULL];
						
					} @catch (NSException* e) {
						N2LogExceptionWithStackTrace(e);
					} @finally {
						[self unlock];
					}
					
					[[BrowserController currentBrowser] emptyDeleteQueueNow: self];
					
					fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
					
					free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue]/1024/1024;
				} while (free < freeMemoryRequested && [unlockedStudies count] > 2);
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			}
			
			NSLog(@"------------------- Finishing autoCleanDatabaseFreeSpace");
			
			// refresh database
			[NSNotificationCenter.defaultCenter postNotificationName:_O2AddToDBAnywayNotification object:self userInfo:nil];
			[NSNotificationCenter.defaultCenter postNotificationName:_O2AddToDBAnywayCompleteNotification object:self userInfo:nil];
			[NSNotificationCenter.defaultCenter postNotificationName:OsirixAddToDBNotification object:self userInfo:nil];
			[NSNotificationCenter.defaultCenter postNotificationName:OsirixAddToDBCompleteNotification object:self userInfo:nil];
		}
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_cleanLock unlock];
	}
}

-(void)_cleanForFreeSpaceWarning {
	NSRunCriticalAlertPanel(NSLocalizedString(@"Warning", nil), NSLocalizedString(@"Your hard disk is FULL! Major risks of failure! Clean your database!!", nil), NSLocalizedString(@"OK",nil), nil, nil);
}

@end
