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


#import "DicomDatabase+Routing.h"
#import "DicomImage.h"
#import "QueryController.h"
#import "N2Debug.h"
#import "DCMTKStoreSCU.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSThread+N2.h"
#import "DCMTKStudyQueryNode.h"
#import "ThreadsManager.h"
#import "N2Stuff.h"


@interface DicomDatabase (RoutingPrivate)

-(NSMutableArray*)routingSendQueues;
-(NSRecursiveLock*)routingLock;

+(void)_syncRoutingTimer;

@end

@implementation DicomDatabase (Routing)

-(void)initRouting {
    if (self.isMainDatabase) {
        _routingSendQueues = [[NSMutableArray alloc] init];
        _routingLock = [[NSRecursiveLock alloc] init];
    } else {
        _routingSendQueues = [[self.mainDatabase routingSendQueues] retain];
        _routingLock = [[self.mainDatabase routingLock] retain];
    }
    
	[DicomDatabase _syncRoutingTimer];
}

-(void)deallocRouting {
	NSRecursiveLock* temp;
	
    if (self.isMainDatabase) {
        temp = _routingLock;
        [temp lock]; // if currently routing, wait until finished
        _routingLock = nil;
        [temp unlock];
        [temp release];
    } else {
        [_routingLock release];
    }
	
	[_routingSendQueues release]; _routingSendQueues = nil;
}

-(NSMutableArray*)routingSendQueues {
    return _routingSendQueues;
}

-(NSRecursiveLock*)routingLock {
    return _routingLock;
}

+(void)_syncRoutingTimer {
	static NSTimer* routingTimer = nil;
	
	if (routingTimer)
		return;
	
	routingTimer = [[NSTimer timerWithTimeInterval:30 target:self selector:@selector(_routingTimerCallback:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop mainRunLoop] addTimer:routingTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop mainRunLoop] addTimer:routingTimer forMode:NSDefaultRunLoopMode];
}

+(void)_routingTimerCallback:(NSTimer*)timer {
	for (DicomDatabase* dbi in [self allDatabases])
		if (dbi.isLocal)
			[dbi initiateRoutingUnlessAlreadyRouting];
}

-(void)initiateRoutingUnlessAlreadyRouting {
	if ([_routingLock tryLock])
		@try {
			[self performSelectorInBackground:@selector(_routingThread) withObject:nil];
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		} @finally {
			[_routingLock unlock];
		}
	//else NSLog(@"Warning: couldn't initiate routing"); // who cares
}

-(void)_routingErrorMessage:(NSDictionary*)dict {
	if (![NSUserDefaults.standardUserDefaults boolForKey:@"ShowErrorMessagesForAutorouting"] || [NSUserDefaults.standardUserDefaults boolForKey: @"hideListenerError"]) return;
	
	NSException	*ne = [dict objectForKey: @"exception"];
	NSDictionary *server = [dict objectForKey:@"server"];
	
	NSString	*message = [NSString stringWithFormat:@"%@\r\r%@\r%@\r\rServer:%@-%@:%@", NSLocalizedString(@"Autorouting DICOM StoreSCU operation failed.\rI will try again in 30 secs.", nil), [ne name], [ne reason], [server objectForKey:@"AETitle"], [server objectForKey:@"Address"], [server objectForKey:@"Port"]];
	
	NSAlert* alert = [[NSAlert new] autorelease];
	[alert setMessageText: NSLocalizedString(@"Autorouting Error",nil)];
	[alert setInformativeText: message];
	[alert setShowsSuppressionButton:YES];
	[alert runModal];
	if ([[alert suppressionButton] state] == NSOnState)
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"ShowErrorMessagesForAutorouting"];
}

-(void)_routingExecuteSend:(NSArray*)samePatientArray server:(NSDictionary*)server dictionary:(NSDictionary*)dict {
	if (!samePatientArray.count)
		return;
	
	NSLog( @" Autorouting: %@ - %@", [[samePatientArray objectAtIndex: 0] valueForKeyPath:@"series.study.name"], N2SingularPluralCount(samePatientArray.count, @"object", @"objects"));
	
    NSMutableDictionary* xp = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"threadStatus"];
    [xp addEntriesFromDictionary:server];
    [xp setObject:self forKey:@"DicomDatabase"];
    
	DCMTKStoreSCU* storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET: [NSUserDefaults defaultAETitle] 
															  calledAET: [server objectForKey:@"AETitle"] 
															   hostname: [server objectForKey:@"Address"] 
																   port: [[server objectForKey:@"Port"] intValue] 
															filesToSend: [samePatientArray valueForKey: @"completePath"]
														 transferSyntax: [[server objectForKey:@"TransferSyntax"] intValue] 
															compression: 1.0
														extraParameters: xp];
	
	@try {
        NSThread.currentThread.supportsCancel = YES;
		[storeSCU run:self];
	} @catch (NSException *ne) {
		NSLog( @"Autorouting FAILED : %@", ne);
		
		[self performSelectorOnMainThread:@selector(_routingErrorMessage:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ne, @"exception", server, @"server", nil] waitUntilDone: NO];
		
		NSThread.currentThread.status = NSLocalizedString( @"Sending failed. Will re-try later...", nil);
		[NSThread sleepForTimeInterval: 4];
		
		// We will try again later...
		
		if ([[dict valueForKey: @"failureRetry"] intValue] > 0) {
			NSLog( @"Autorouting for %@ : failure count: %d", [[samePatientArray objectAtIndex: 0] valueForKeyPath:@"series.study.name"], [[dict valueForKey: @"failureRetry"] intValue]);
			@synchronized (_routingSendQueues) {
				[_routingSendQueues addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                [NSMutableArray arrayWithArray:[samePatientArray valueForKey:@"objectID"]], @"objectIDs",
                                                [server objectForKey:@"Description"], @"server", 
                                                [dict valueForKey:@"routingRule"], @"routingRule", 
                                                [NSNumber numberWithInt: [[dict valueForKey:@"failureRetry"] intValue]-1], @"failureRetry", nil]];
			}
		}
	}
	
	[storeSCU release];
	storeSCU = nil;
}

-(void)_routingThread
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	@try
    {
        BOOL isQueueEmpty = YES;
        @synchronized (_routingSendQueues)
        {
			if( _routingSendQueues.count)
                isQueueEmpty = NO;
        }
        
        if( isQueueEmpty == NO)
        {
            NSThread* thread = [NSThread currentThread];
            thread.name = NSLocalizedString(@"Routing...", nil);
            [self.independentDatabase routing];
        }
	}
    @catch (NSException * e)
    {
		N2LogExceptionWithStackTrace(e);
	}
    @finally
    {
		[pool release];
	}
}

-(void)routing {
	[_routingLock lock];
	@try {
		NSThread* thread = [NSThread currentThread];
		
		NSArray* serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"SERVERS"];
		
		NSArray* routingSendQueues = nil;
		@synchronized (_routingSendQueues) {
			routingSendQueues = [[_routingSendQueues copy] autorelease];
			[_routingSendQueues removeAllObjects];
		}
		
		if (routingSendQueues.count) {
			[ThreadsManager.defaultManager addThreadAndStart:thread];
			
			NSInteger total = 0;
			for (NSDictionary *copy in routingSendQueues)
				for (NSDictionary* aServer in serversArray)
					if ([[aServer objectForKey:@"Description"] isEqualToString:[copy objectForKey:@"server"]]) {
						total += [[copy objectForKey:@"objectIDs"] count];
						break;
					}
            
            NSLog(@"______________________________________________");
			NSLog(@" Autorouting Queue START: %@, %@", N2SingularPluralCount(routingSendQueues.count, @"list", @"lists"), N2SingularPluralCount(total, @"item", @"items"));
			
			NSInteger sent = 0;
			for (NSDictionary* copy in routingSendQueues) {
				NSArray* objectIDs = [copy objectForKey:@"objectIDs"];
                NSArray* objectsToSend = [self objectsWithIDs:objectIDs];
				
				[thread enterOperationWithRange:1.0*sent/total:1.0*objectsToSend.count/total];
				sent += objectsToSend.count;
				
				NSString* serverName = [copy objectForKey:@"server"];
				thread.status = [NSString stringWithFormat:NSLocalizedString(@"Forwarding %@ to %@", nil), N2LocalizedSingularPluralCount(objectsToSend.count, @"file", @"files"), serverName];
				
				NSDictionary* server = nil;
				for (NSDictionary* aServer in serversArray)
					if ([[aServer objectForKey:@"Description"] isEqualToString:serverName]) {
						NSLog(@" Autorouting destination: %@ - %@", [aServer objectForKey:@"Description"], [aServer objectForKey:@"Address"]);
						server = aServer;
						break;
					}
				
				if (server) {
					@try {
						NSSortDescriptor	*sort = [[[NSSortDescriptor alloc] initWithKey:@"series.study.patientID" ascending:YES] autorelease];
						NSArray				*sortDescriptors = [NSArray arrayWithObject: sort];
						
						objectsToSend = [objectsToSend sortedArrayUsingDescriptors: sortDescriptors];
						
						NSString			*previousPatientUID = nil;
						NSMutableArray		*samePatientArray = [NSMutableArray arrayWithCapacity: [objectsToSend count]];
						
						for( NSManagedObject *objectToSend in objectsToSend)
						{
							@try
							{
								if( [[NSFileManager defaultManager] fileExistsAtPath: [objectToSend valueForKey: @"completePath"]]) // Dont try to send files that are not available
								{
									if( previousPatientUID && [previousPatientUID isEqualToString: [objectToSend valueForKeyPath:@"series.study.patientID"]])
									{
										[samePatientArray addObject: objectToSend];
									}
									else
									{
										// Send the collected files from the same patient
										
										if( [samePatientArray count]) [self _routingExecuteSend: samePatientArray server: server dictionary: copy];
										
										// Reset
										[samePatientArray removeAllObjects];
										[samePatientArray addObject: objectToSend];
										
										previousPatientUID = [objectToSend valueForKeyPath:@"series.study.patientID"];
									}
								}
							}
							@catch( NSException *ne)
							{
								NSLog( @"----- Autorouting Prepare exception: %@", ne);
							}
						}
						
						if (samePatientArray.count)
							[self _routingExecuteSend:samePatientArray server:server dictionary:copy];
					} @catch (NSException* e) {
						N2LogExceptionWithStackTrace(e);
					}
				} else {
					N2LogError(@"Server not found for autorouting: %@", serverName);
				}
				
				[thread exitOperation];
				
				if (thread.isCancelled)
					break;
			}
			
			NSLog(@"______________________________________________");
		}
		
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_routingLock unlock];
	}
}

-(void)addImages:(NSArray*)_dicomImages toSendQueueForRoutingRule:(NSDictionary*)routingRule {
	@synchronized (_routingSendQueues) {
		NSMutableArray* dicomImages = [NSMutableArray arrayWithArray:_dicomImages];
		
		// are these images already in the queue, with same routingRule ?
		for (NSDictionary* order in _routingSendQueues)
			if ([routingRule isEqualToDictionary:[order valueForKey:@"routingRule"]]) {
                NSMutableArray* orderObjectIDs = [order valueForKey:@"objectIDs"];
                
				NSArray* orderFilePaths = [[self objectsWithIDs:orderObjectIDs] valueForKey:@"completePath"];
				
				// are the files already in queue for same filter?
				for (NSInteger i = dicomImages.count-1; i >= 0; --i) {
                    DicomImage* image = [dicomImages objectAtIndex:i];
					if ([orderFilePaths containsObject:[image completePath]])
						[dicomImages removeObject:image];
				}
                
				[orderObjectIDs addObjectsFromArray:[dicomImages valueForKey:@"objectID"]];
                
				[dicomImages removeAllObjects];
			}
		
		if (dicomImages.count)
			[_routingSendQueues addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSMutableArray arrayWithArray:[dicomImages valueForKey:@"objectID"]], @"objectIDs",
                                           [routingRule objectForKey:@"server"], @"server", 
                                           routingRule, @"routingRule", 
                                           [routingRule valueForKey:@"failureRetry"], @"failureRetry", nil]];
	}
}

-(void)applyRoutingRules:(NSArray*)autoroutingRules toImages:(NSArray*)newImages {
#ifndef OSIRIX_LIGHT
	if (!autoroutingRules)
		autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey:@"AUTOROUTINGDICTIONARY"];
	
	for (NSDictionary* routingRule in autoroutingRules)
		if (![routingRule valueForKey:@"activated"] || [[routingRule valueForKey:@"activated"] boolValue]) {
            
			//			[self.managedObjectContext lock];
			
			NSPredicate	*predicate = nil;
			NSArray	*result = nil;
			
			@try {
				if ([[routingRule objectForKey:@"filterType"] intValue] == 0)
					predicate = [DicomDatabase predicateForSmartAlbumFilter:[routingRule objectForKey:@"filter"]];
				else { // GeneratedByOsiriX filterType
					/*if (generatedByOsiriX)
					 predicate = [NSPredicate predicateWithValue: YES];
					 else
					 {
					 if( manually)
					 {
					 NSMutableArray *studies = [NSMutableArray arrayWithArray: [newImages valueForKeyPath: @"series.study"]];
					 [studies removeDuplicatedObjects];
					 for( DicomStudy *study in studies)
					 {
					 [study archiveAnnotationsAsDICOMSR];
					 [study archiveReportAsDICOMSR];
					 
					 for( DicomImage *im in [[[study roiSRSeries] valueForKey: @"images"] allObjects])
					 [im setValue: [NSNumber numberWithBool: YES] forKey: @"generatedByOsiriX"];
					 
					 for( DicomImage *im in [[[study reportSRSeries] valueForKey: @"images"] allObjects])
					 [im setValue: [NSNumber numberWithBool: YES] forKey: @"generatedByOsiriX"];
					 
					 [[study annotationsSRImage] setValue: [NSNumber numberWithBool: YES] forKey: @"generatedByOsiriX"];
					 }
					 */
					predicate = [NSPredicate predicateWithFormat:@"generatedByOsiriX == YES"];
					/*}
					 else
					 predicate = [NSPredicate predicateWithValue: NO];
					 }*/
				}
				
				if (predicate)
					result = [newImages filteredArrayUsingPredicate:predicate];
				
				if (result.count) {
					if ([[routingRule valueForKey:@"previousStudies"] intValue] > 0 && [[routingRule objectForKey: @"filterType"] intValue] == 0)
					{
						NSMutableDictionary *patients = [NSMutableDictionary dictionary];
						
						// for each study
						for( id im in result)
						{
							if( [patients objectForKey: [im valueForKeyPath:@"series.study.patientUID"]] == nil)
								[patients setObject: [im valueForKeyPath:@"series.study"] forKey: [im valueForKeyPath:@"series.study.patientUID"]];
						}
						
						for( NSString *patientUID in [patients allKeys])
						{
							NSLog( @"%@", patientUID);
							
							id study = [patients objectForKey: patientUID];
							
                            // Pourquoi n'y a-t-il pas de lock? Oui il en faut bien mais pas pendant TOUT le routage... seulement ici:
                            NSArray *studiesArray = [self objectsForEntity:self.studyEntity predicate:[NSPredicate predicateWithFormat:  @"(patientUID == %@)", patientUID]];
							
							if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
							{
								NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
								NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
								[sort release];
								NSMutableArray* s = [[[studiesArray sortedArrayUsingDescriptors: sortDescriptors] mutableCopy] autorelease];
								// remove original study from array
								[s removeObject: study];
								
								studiesArray = [NSArray arrayWithArray: s];
								
								// did we already send these studies ? If no, send them !
								
								//								if (autoroutingPreviousStudies == nil) autoroutingPreviousStudies = [[NSMutableDictionary dictionary] retain];
								
								int previousNumber = [[routingRule valueForKey:@"previousStudies"] intValue];
								
								for( id s in studiesArray)
								{
									NSString *key = [NSString stringWithFormat:@"%@ -> %@", [s valueForKey: @"studyInstanceUID"], [routingRule objectForKey:@"server"]];
									//									NSDate *when = [autoroutingPreviousStudies objectForKey: key];
									
									BOOL found = YES;
									
									if( [[routingRule valueForKey: @"previousModality"] boolValue])
									{
										if( [s valueForKey:@"modality"] && [study valueForKey:@"modality"])
										{
											if( [[study valueForKey:@"modality"] rangeOfString: [s valueForKey:@"modality"]].location == NSNotFound) found = NO;
										}
										else found = NO;
									}
									
									if( [[routingRule valueForKey: @"previousDescription"] boolValue])
									{
										if( [s valueForKey:@"studyName"] && [study valueForKey:@"studyName"])
										{
											if( [[study valueForKey:@"studyName"] rangeOfString: [s valueForKey:@"studyName"]].location == NSNotFound) found = NO;
										}
										else found = NO;
									}
									
									if( found && previousNumber > 0)
									{
										previousNumber--;
										
										// If we sent it more than 3 hours ago, re-send it
										//if( when == nil || [when timeIntervalSinceNow] < -60*60*3*/)
										{
											//											[autoroutingPreviousStudies setObject: [NSDate date] forKey: key];
											
											//for( NSManagedObject *series in [[s valueForKey:@"series"] allObjects])
											//	result = [result arrayByAddingObjectsFromArray: [[series valueForKey:@"images"] allObjects]];
										}
									}
								}
							}
						}
					}
					
					if( [[routingRule valueForKey:@"cfindTest"] boolValue] && [[routingRule objectForKey: @"filterType"] intValue] == 0)
					{
						NSMutableDictionary *studies = [NSMutableDictionary dictionary];
						
						for( id im in result)
						{
							if( [studies objectForKey: [im valueForKeyPath:@"series.study.studyInstanceUID"]] == nil)
								[studies setObject: [im valueForKeyPath:@"series.study"] forKey: [im valueForKeyPath:@"series.study.studyInstanceUID"]];
						}
						
						for( NSString *studyUID in [studies allKeys])
						{
							NSArray *serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
							
							NSString		*serverName = [routingRule objectForKey:@"server"];
							NSDictionary	*server = nil;
							
							for ( NSDictionary *aServer in serversArray)
							{
								if ([[aServer objectForKey:@"Description"] isEqualToString: serverName]) 
								{
									server = aServer;
									break;
								}
							}
							
							if( server)
							{
								NSArray *s = [QueryController queryStudyInstanceUID: studyUID server: server showErrors: NO];
								
								if( [s count])
								{
									if( [s count] > 1)
										NSLog( @"Uh? multiple studies with same StudyInstanceUID on the distal node....");
									
									DCMTKStudyQueryNode* studyNode = [s lastObject];
									
									if( [[studyNode valueForKey:@"numberImages"] intValue] >= [[[studies objectForKey: studyUID] valueForKey: @"noFiles"] intValue])
									{
										// remove them, there are already there ! *probably*
										
										NSLog( @"Already available on the distant node : we will not send it.");
										
										NSMutableArray *r = [NSMutableArray arrayWithArray: result];
										
										for( int i = 0 ; i < [r count] ; i++)
										{
											if( [[[r objectAtIndex: i] valueForKeyPath: @"series.study.studyInstanceUID"] isEqualToString: studyUID])
											{
												[r removeObjectAtIndex: i];
												i--;
											}
										}
										
										result = r;
									}
								}
							}
						}
					}
				}
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
				result = nil;
			}
			
			if ([result count])
				[self addImages:result toSendQueueForRoutingRule:routingRule];
		}
	
	// Do some cleaning
	
	/*	if( autoroutingPreviousStudies)
	 {
	 for( NSString *key in [autoroutingPreviousStudies allKeys])
	 {
	 if( [[autoroutingPreviousStudies objectForKey: key] timeIntervalSinceNow] < -60*60*3)
	 {
	 [autoroutingPreviousStudies removeObjectForKey: key];
	 }
	 }
	 }
	 
	 [splash close];
	 [splash release];*/
#endif	
	
}

@end
