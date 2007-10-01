//
//  OsiriXSCP.m
//  OsiriX
//
//  Created by Lance Pysher on 3/22/05.

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

#import "OsiriXSCPDataHandler.h"

#import "browserController.h"
#import "AppController.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomSeries.h"


extern AppController		*appController;


NSString * const OsiriXFileReceivedNotification = @"OsiriXFileReceivedNotification";

@implementation OsiriXSCPDataHandler

- (void)dealloc
{
	[specificCharacterSet release];
	[findArray release];
	[moveArray release];
	[logEntry setValue:@"Complete" forKey:@"message"];
	if (tempMoveFolder && [[NSFileManager defaultManager] fileExistsAtPath:tempMoveFolder])
		[[NSFileManager defaultManager] removeFileAtPath:tempMoveFolder handler:nil];
	[tempMoveFolder release];
	[findEnumerator release];
	[moveEnumerator release];
	[logEntry release];
	[super dealloc];
}


- (void) finalize {
	if (tempMoveFolder && [[NSFileManager defaultManager] fileExistsAtPath:tempMoveFolder])
		[[NSFileManager defaultManager] removeFileAtPath:tempMoveFolder handler:nil];
	[super finalize];
}


+ (id)requestDataHandlerWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug{
	return [[[OsiriXSCPDataHandler alloc] initWithDestinationFolder:(NSString *)destination
					debugLevel:(int)debug] autorelease];
}


- (id)initWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug{
	//NSLog(@"init NetworkDataHandler");
	if (self = [super initWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug])
	{
		commandType = 0x0001;
		logEntry = 0L;
	}
	return self;
}

- (void)cFindResponse{
	[responseMessage release];
	response = nil;	
	isDone = NO;	
}

- (void) makeUseOfDataSet:(DCMObject *)object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (commandType == 0x0001){ // C Store	
		NS_DURING
		NSString *path = [NSString stringWithFormat: @"%@/%@.dcm", folder, [object attributeValueWithName:@"SOPInstanceUID"]];
		
		if (debugLevel > 0)
			NSLog(@"Save file: %@", path);
		[object writeToFile:path  withTransferSyntax:[object transferSyntax] quality:DCMLosslessQuality atomically:YES];
		NS_HANDLER
			NSLog(@"Error saving DICOM dataset: %@", [localException name]);
		NS_ENDHANDLER
	}
	else if (commandType == 0x0021)  { //move
		NS_DURING
			/*
			object will be search attributes
				need to parse request into CompoundPredicate
				collect files
				return each file as composite response 
				and end with setting cMove Response to complete
			*/
			
			NSString *moveDestination = [[moveRequest moveDestination] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			NSLog( @"C-MOVE : MoveDestination : %@", moveDestination);
			
//			NSArray *servers = serversArray;
//			NSArray					*bonjourServers		= [[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices];
			NSArray					*serversArray		= [DCMNetServiceDelegate DICOMServersList];			
			NSArray					*servers;
			
//			if ([serversArray count] > 0)
//				servers = [serversArray arrayByAddingObjectsFromArray:bonjourServers];
//			else
//				servers = bonjourServers;
			
			servers = serversArray;
			
			NSString *theirAET;
			NSString *hostname;
			NSString *port;
			
			NSPredicate *serverPredicate = [NSPredicate predicateWithFormat: @"AETitle == %@", moveDestination];
			NSArray *serverSelection = [serversArray filteredArrayUsingPredicate:serverPredicate];
			
			//if empty. Try NSNetService
			if ([serverSelection count] == 0) {
				serverPredicate = [NSPredicate predicateWithFormat:@"name == %@", moveDestination];
				serverSelection = [serversArray filteredArrayUsingPredicate:serverPredicate];
			}
			numberMoving = 0;
//			NSNetService *netService= nil;
			
			if ([serverSelection count])
			{
				id server = [serverSelection objectAtIndex:0];
//				if ([server isMemberOfClass:[NSNetService class]]) {
//					
//					netService = server;
//					theirAET = [server name];
//					hostname = [server hostName];
//					port = @"";
//				}
//				else {
					//NSLog(@"
					theirAET = [server objectForKey:@"AETitle"];
					hostname = [server objectForKey:@"Address"];
					port = [server objectForKey:@"Port"];
//				}
				NSLog(@"Server: %@", [server description]);
				NSManagedObjectModel *model = [[BrowserController currentBrowser] managedObjectModel];
				NSError *error = 0L;
				NSString *searchType = [object attributeValueWithName:@"Query/RetrieveLevel"];
				NSEntityDescription *entity;
				NSPredicate *predicate = [self predicateForObject:object];
				NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
				if ([searchType isEqualToString:@"STUDY"])
					entity = [[model entitiesByName] objectForKey:@"Study"];
				else if ([searchType isEqualToString:@"SERIES"])
					entity = [[model entitiesByName] objectForKey:@"Series"];
				else if ([searchType isEqualToString:@"IMAGE"]) 
					entity = [[model entitiesByName] objectForKey:@"Image"];
				else 
					entity = nil;
				[request setEntity:entity];
				[request setPredicate:predicate];
				
				error = 0L;
				NSManagedObjectContext	*context = [[BrowserController currentBrowser] managedObjectContext];
				NSArray *fetchArray = [context executeFetchRequest:request error:&error];
				
				if (error) 
					NSLog(@"error: %@", [error description]);
					
				if ([fetchArray count]) {
					//NSLog(@"found object to move: %@", [fetchArray description]);
					NSMutableSet *set = [NSMutableSet set];
					id object;
					for (object in fetchArray) {
						[set unionSet:[object paths]];
					}
					numberMoving = [set count];
					// need to modify objects in case server is netService
					if ([set count]) {
						//	NSLog(@"get ready to move");
							NSArray *filesToSend = [set allObjects];
							NSArray *objects; 							
							NSArray *keys = [NSArray arrayWithObjects:@"filesToSend", @"compression", @"transferSyntax", @"callingAET", @"calledAET", @"hostname", @"port", @"moveHandler",  nil];
							//NSLog(@"create move Params");
//							if (netService) {
//								//NSLog(@"add netService");
//								objects = [NSArray arrayWithObjects:filesToSend, [NSNumber numberWithInt:DCMLosslessQuality], [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax], [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], theirAET, hostname, port, self, netService,   nil];
//								keys = [NSArray arrayWithObjects:@"filesToSend", @"compression", @"transferSyntax", @"callingAET", @"calledAET", @"hostname", @"port", @"moveHandler",  @"netService", nil];
//							}
//							else {
								objects = [NSArray arrayWithObjects:filesToSend, [NSNumber numberWithInt:DCMLosslessQuality], [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax], [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], theirAET, hostname, port, self,   nil];
								keys = [NSArray arrayWithObjects:@"filesToSend", @"compression", @"transferSyntax", @"callingAET", @"calledAET", @"hostname", @"port", @"moveHandler",  nil];
//							}
							NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
							//NSLog(@"create dictionary");
							//NSLog(@"Move params: %@", [params description]);
							[DCMStoreSCU sendWithParameters:params];
					}
						else{
							DCMCMoveResponse *moveResponse = [DCMCMoveResponse cMoveResponseWithAffectedSOPClassUID:[moveRequest affectedSOPClassUID]  
								priority:[moveRequest priority]
								messageIDBeingRespondedTo:[moveRequest messageIDBeingRespondedTo]
								remainingSuboperations:0x0000
								completedSuboperations:0x0000
								failedSuboperations:0x0000
								warningSuboperations:0x0000
								status:0xA801];
						
						[scpDelegate sendCommand:moveResponse data:[DCMObject dcmObject] forAffectedSOPClassUID:[moveRequest affectedSOPClassUID]];
					}
				}
				else{
					DCMCMoveResponse *moveResponse = [DCMCMoveResponse cMoveResponseWithAffectedSOPClassUID:[moveRequest affectedSOPClassUID]  
						priority:[moveRequest priority]
						messageIDBeingRespondedTo:[moveRequest messageIDBeingRespondedTo]
						remainingSuboperations:0x0000
						completedSuboperations:0x0000
						failedSuboperations:0x0000
						warningSuboperations:0x0000
						status:0xA702];
				
					[scpDelegate sendCommand:moveResponse data:[DCMObject dcmObject] forAffectedSOPClassUID:[moveRequest affectedSOPClassUID]];
				}
			}
			else
			{
				NSLog( @"C-MOVE MoveDestination NOT FOUND... on the local DICOM nodes list (see Preferences)");
			
				DCMCMoveResponse *moveResponse = [DCMCMoveResponse cMoveResponseWithAffectedSOPClassUID:[moveRequest affectedSOPClassUID]  
						priority:[moveRequest priority]
						messageIDBeingRespondedTo:[moveRequest messageIDBeingRespondedTo]
						remainingSuboperations:0x0000
						completedSuboperations:0x0000
						failedSuboperations:0x0000
						warningSuboperations:0x0000
						status:0xA801];
				
				[scpDelegate sendCommand:moveResponse data:[DCMObject dcmObject] forAffectedSOPClassUID:[moveRequest affectedSOPClassUID]];

			}
		NS_HANDLER
			NSLog(@"Error MOVING DICOM dataset: %@", [localException name]);
		NS_ENDHANDLER
		
	}
	else if (commandType == 0x0020) { // find
	
		/*
		object will be search attributes
			need to parse request into CompoundPredicate
			collect files
			return each file as composite response 
			and end with setting cFind Response to complete
		*/
		//NSLog(@"query");
		NSManagedObjectModel *model = [[BrowserController currentBrowser] managedObjectModel];
		NSError *error = 0L;
		NSString *searchType = [object attributeValueWithName:@"Query/RetrieveLevel"];
		NSEntityDescription *entity;
		NSPredicate *predicate = [self predicateForObject:object];
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		if ([searchType isEqualToString:@"STUDY"])
			entity = [[model entitiesByName] objectForKey:@"Study"];
		else if ([searchType isEqualToString:@"SERIES"])
			entity = [[model entitiesByName] objectForKey:@"Series"];
		else if ([searchType isEqualToString:@"IMAGE"]) 
			entity = [[model entitiesByName] objectForKey:@"Image"];
		else 
			entity = nil;
		[request setEntity:entity];
		[request setPredicate:predicate];
		//[request setPredicate: [NSPredicate predicateWithValue:YES]];
		
		NS_DURING
		error = 0L;
		NSManagedObjectContext	*context = [[BrowserController currentBrowser] managedObjectContext];
		NSArray *fetchArray = [context executeFetchRequest:request error:&error];
		if (!error && [fetchArray count]) {
			unsigned short remaining = [fetchArray count];
			unsigned short completed = 0;
		//	unsigned short failed = 0;
		//	unsigned short warning = 0;
			
			id fetchedObject;
			//NSLog(@"fetch: %@", [fetchArray description]);
			for (fetchedObject in fetchArray){
				DCMObject *object = nil;
				NSLog(@"Fetch: %@", [fetchedObject description]);
				if ([searchType isEqualToString:@"STUDY"])
					object = [self studyObjectForFetchedObject:fetchedObject];
				else if ([searchType isEqualToString:@"SERIES"])
					object = [self seriesObjectForFetchedObject:fetchedObject];
				else if ([searchType isEqualToString:@"IMAGE"]) 
					object = [self imageObjectForFetchedObject:fetchedObject];
					
				if ([[findRequest dcmObject] attributeValueWithName:@"SpecificCharacterSet"])
					[object setAttributeValues:[NSMutableArray arrayWithObject:[[findRequest dcmObject] attributeValueWithName:@"SpecificCharacterSet"]] forName:@"SpecificCharacterSet"];
				
				DCMCFindResponse *findResponse = [DCMCFindResponse cFindResponseWithAffectedSOPClassUID:[findRequest affectedSOPClassUID]  
						priority:[findRequest priority]
						messageIDBeingRespondedTo:[findRequest messageIDBeingRespondedTo]
						remainingSuboperations:remaining--
						completedSuboperations:completed++
						failedSuboperations:0x0000
						warningSuboperations:0x0000
						status:0xFF00];
				
				[scpDelegate sendCommand:findResponse data:object forAffectedSOPClassUID:[findRequest affectedSOPClassUID]];

			}
			DCMCFindResponse *findResponse = [DCMCFindResponse cFindResponseWithAffectedSOPClassUID:[findRequest affectedSOPClassUID]  
						priority:[findRequest priority]
						messageIDBeingRespondedTo:[findRequest messageIDBeingRespondedTo]
						remainingSuboperations:remaining--
						completedSuboperations:completed++
						failedSuboperations:0x0000
						warningSuboperations:0x0000
						status:0x0000]; 
			[scpDelegate sendCommand:findResponse data:object forAffectedSOPClassUID:[findRequest affectedSOPClassUID]];
			//response = [[findResponse data] retain];
			//[responseMessage release];
			//responseMessage = [findResponse retain];
			isDone = YES;
		}		
		else {
			//NSLog(@"NO MATCHES");
			DCMCFindResponse *findResponse = [DCMCFindResponse cFindResponseWithAffectedSOPClassUID:[findRequest affectedSOPClassUID]  
						priority:[findRequest priority]
						messageIDBeingRespondedTo:[findRequest messageIDBeingRespondedTo]
						remainingSuboperations:0x0000
						completedSuboperations:0x0000
						failedSuboperations:0x0000
						warningSuboperations:0x0000
						status:0x0000]; 
			[scpDelegate sendCommand:findResponse data:object forAffectedSOPClassUID:[findRequest affectedSOPClassUID]];
			//response = [[findResponse data] retain];
			//[responseMessage release];
			//responseMessage = [findResponse retain];
			isDone = YES;
			if (error)
				NSLog(@"Fetch error: %@", [error description]);
		}
		
		//NSLog(@"Find response: %@", [response description]);
		NS_HANDLER
			DCMCFindResponse *findResponse = [DCMCFindResponse cFindResponseWithAffectedSOPClassUID:[findRequest affectedSOPClassUID]  
						priority:[findRequest priority]
						messageIDBeingRespondedTo:[findRequest messageIDBeingRespondedTo]
						remainingSuboperations:0x0000
						completedSuboperations:0x0000
						failedSuboperations:0x0000
						warningSuboperations:0x0000
						status:0x0000]; 
			[scpDelegate sendCommand:findResponse data:object forAffectedSOPClassUID:[findRequest affectedSOPClassUID]];
			isDone = YES;
		NS_ENDHANDLER
	}
	[pool release];
	//NSLog(@"End make use of Dataset");
	
}

- (NSPredicate *)predicateForObject:(DCMObject *)object{
	//NSPredicate *compoundPredicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
	NSPredicate *compoundPredicate = [NSPredicate predicateWithValue:YES];
	NSEnumerator *enumerator = [[object attributes] keyEnumerator];
	NSString *searchType = [object attributeValueWithName:@"Query/RetrieveLevel"];
	//should be STUDY, SERIES OR IMAGE
	NSLog(@"predicateForObject: %@", [object description]);
	NSString *key;
	while (key = [enumerator nextObject]){
		id value;
		//NSExpression *expression;
		NSPredicate *predicate;
		DCMAttribute *attr = [[object attributes] objectForKey:key];
		if ([searchType isEqualToString:@"STUDY"]) {
			// check for dicom
			compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"hasDICOM == %d", YES], compoundPredicate, nil]];
			//compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject: compoundPredicate, nil]];
			if ([[[attr attrTag] name] isEqualToString:@"PatientsName"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", value];
	
			}
			else if ([[[attr attrTag] name] isEqualToString:@"PatientID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"patientID LIKE[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"AccessionNumber"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"accessionNumber LIKE[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"StudyInstanceUID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"StudyID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"id == %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"StudyDescription"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"studyName LIKE[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"InstitutionName"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"institutionName LIKE[cd] %@", value];

			}
			else if ([[[attr attrTag] name] isEqualToString:@"ReferringPhysiciansName"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"referringPhysician LIKE[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"PerformingPhysiciansName"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"performingPhysician LIKE[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"PatientsBirthDate"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"dateOfBirth >= CAST(%lf, \"NSDate\") AND dateOfBirth <= CAST(%lf, \"NSDate\")", [self startOfDay:value], [self endOfDay:value]];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"StudyDate"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					/*			
					subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\") AND date <= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate]];
					*/
					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%lf, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						DCMCalendarDate *startDate = [DCMCalendarDate dicomDate:[values objectAtIndex:0]];
						DCMCalendarDate *endDate = [DCMCalendarDate dicomDate:[values objectAtIndex:1]];
						//NSLog(@"startDate: %@", [startDate description]);
						//NSLog(@"endDate :%@", [endDate description]);
						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\")", [self startOfDay:startDate]];
						
						//expression = [NSExpression expressionForConstantValue:(NSDate *)endDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")",[self endOfDay:endDate]];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}
				else{
					predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\") AND date < CAST(%lf, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
				}
			}
			
			else if ([[[attr attrTag] name] isEqualToString:@"StudyTime"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime <= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime >= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						NSNumber *startDate = [NSNumber numberWithInt:[[values objectAtIndex:0] intValue]];
						NSNumber *endDate = [NSNumber numberWithInt:[[values objectAtIndex:1] intValue]];
						//NSLog(@"startDate: %@", [startDate description]);
						//NSLog(@"endDate :%@", [endDate description]);
						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"dicomTime >= %@",startDate];
						
						//expression = [NSExpression expressionForConstantValue:(NSDate *)endDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"dicomTime <= %@",endDate];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}

				else{
					predicate = [NSPredicate predicateWithFormat:@"dicomTime == %@", [value dateAsNumber]];
				}
			}
			else
				predicate = nil;
				
			if (predicate)
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, compoundPredicate, nil]];
		}
		else if ([searchType isEqualToString:@"SERIES"]) {
			//NSLog(@"Series search");
			if ([[[attr attrTag] name] isEqualToString:@"StudyInstanceUID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesInstanceUID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", value];
			} 
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesDescription"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesNumber"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"id == %@", value];
			} 
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesDate"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					//id newValue = [DCMCalendarDate dicomDate:query];
					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%lf, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						DCMCalendarDate *startDate = [DCMCalendarDate dicomDate:[values objectAtIndex:0]];
						DCMCalendarDate *endDate = [DCMCalendarDate dicomDate:[values objectAtIndex:1]];
						//NSLog(@"startDate: %@", [startDate description]);
						//NSLog(@"endDate :%@", [endDate description]);
						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\")", [self startOfDay:startDate]];
						
						//expression = [NSExpression expressionForConstantValue:(NSDate *)endDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")",[self endOfDay:endDate]];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}
				else{
					predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\") AND date < CAST(%lf, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
				}
			}
			
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesTime"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime <= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime >= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						NSNumber *startDate = [NSNumber numberWithInt:[[values objectAtIndex:0] intValue]];
						NSNumber *endDate = [NSNumber numberWithInt:[[values objectAtIndex:1] intValue]];

						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"dicomTime >= %@",startDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"dicomTime <= %@",endDate];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}

				else{
					predicate = [NSPredicate predicateWithFormat:@"dicomTime == %@", [value dateAsNumber]];
				}
			}
			else
				predicate = nil;
				
			if (predicate)
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, compoundPredicate, nil]];

		}
		else if ([searchType isEqualToString:@"IMAGE"]) {
		}
	}
	
	NSLog(@"predicateForObject: %@", [compoundPredicate description]);
	return compoundPredicate;
}

- (DCMObject *)studyObjectForFetchedObject:(id)fetchedObject{
	DCMObject *studyObject = [DCMObject dcmObject];
	if ([fetchedObject valueForKey:@"name"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"name"]] forName:@"PatientsName"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
		
	if ([fetchedObject valueForKey:@"patientID"])	
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"patientID"]] forName:@"PatientID"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
	
	if ([fetchedObject valueForKey:@"accessionNumber"])	
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"accessionNumber"]] forName:@"AccessionNumber"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"AccessionNumber"];
	
	if ([fetchedObject valueForKey:@"studyName"])	
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"studyName"]] forName:@"StudyDescription"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"StudyDescription"];
		

	if ([fetchedObject valueForKey:@"date"]){
		////NSNumber *dateNumber = [fetchedObject valueForKey:@"dicomDate"];
		//NSString *dateString = [NSString stringWithFormat:@"%d", [dateNumber intValue]];
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:dicomDate] forName:@"StudyDate"];
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:dicomTime] forName:@"StudyTime"];
	
	}
	else {
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"StudyDate"];
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"StudyTime"];
	}
	
			
	if ([fetchedObject valueForKey:@"studyInstanceUID"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"studyInstanceUID"]] forName:@"StudyInstanceUID"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"StudyInstanceUID"];
	
	if ([fetchedObject valueForKey:@"id"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"id"]] forName:@"StudyID"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"StudyID"];
			
	if ([fetchedObject valueForKey:@"modality"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"modality"]] forName:@"ModalitiesinStudy"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"ModalitiesinStudy"];
	/*		
	if ([fetchedObject valueForKey:@"modalitiesinStudy"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"modalitiesinStudy"]] forName:@"ModalitiesinStudy"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"ModalitiesinStudy"];
	*/	
	if ([fetchedObject valueForKey:@"referringPhysician"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"referringPhysician"]] forName:@"ReferringPhysiciansName"];
		
	if ([fetchedObject valueForKey:@"performingPhysician"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"performingPhysician"]] forName:@"PerformingPhysiciansName"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"PerformingPhysiciansName"];
				
	if ([fetchedObject valueForKey:@"institutionName"])
		[studyObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"institutionName"]] forName:@"InstitutionName"];
	else
		[studyObject setAttributeValues:[NSMutableArray array] forName:@"InstitutionName"];
	
	
	[studyObject setAttributeValues:[NSMutableArray arrayWithObject:@"STUDY"] forName:@"Query/RetrieveLevel"];
	//NSLog(@"object: %@", [studyObject description]);
	return studyObject;
}

- (DCMObject *)seriesObjectForFetchedObject:(id)fetchedObject{
	DCMObject *seriesObject = [DCMObject dcmObject];
	if ([fetchedObject valueForKey:@"name"])	
		[seriesObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"name"]] forName:@"SeriesDescription"];
	else
		[seriesObject setAttributeValues:[NSMutableArray array] forName:@"SeriesDescription"];
		
	if ([fetchedObject valueForKey:@"date"]){
		////NSNumber *dateNumber = [fetchedObject valueForKey:@"dicomDate"];
		//NSString *dateString = [NSString stringWithFormat:@"%d", [dateNumber intValue]];
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		//NSLog(@"date: %@", [[DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]] description]);
		[seriesObject setAttributeValues:[NSMutableArray arrayWithObject:dicomDate] forName:@"SeriesDate"];
		[seriesObject setAttributeValues:[NSMutableArray arrayWithObject:dicomTime] forName:@"SeriesTime"];
	}
	else {
		[seriesObject setAttributeValues:[NSMutableArray array] forName:@"SeriesDate"];
		[seriesObject setAttributeValues:[NSMutableArray array] forName:@"SeriesTime"];
	}

	
	if ([fetchedObject valueForKey:@"modality"])
		[seriesObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"modality"]] forName:@"Modality"];
	else
		[seriesObject setAttributeValues:[NSMutableArray array] forName:@"Modality"];
		
	if ([fetchedObject valueForKey:@"id"])
		[seriesObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"id"]] forName:@"SeriesNumber"];
	else
		[seriesObject setAttributeValues:[NSMutableArray array] forName:@"SeriesNumber"];
			
	if ([fetchedObject valueForKey:@"seriesDICOMUID"])
		[seriesObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"seriesDICOMUID"]] forName:@"SeriesInstanceUID"];
	return seriesObject;
}

- (DCMObject *)imageObjectForFetchedObject:(id)fetchedObject{
	DCMObject *imageObject = [DCMObject dcmObject];
	if ([fetchedObject valueForKey:@"date"]){
		////NSNumber *dateNumber = [fetchedObject valueForKey:@"dicomDate"];
		//NSString *dateString = [NSString stringWithFormat:@"%d", [dateNumber intValue]];
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		[imageObject setAttributeValues:[NSMutableArray arrayWithObject:dicomDate] forName:@"AcquisitionDate"];
		[imageObject setAttributeValues:[NSMutableArray arrayWithObject:dicomTime] forName:@"AcquisitionTime"];
	}
	else {
		[imageObject setAttributeValues:[NSMutableArray array] forName:@"AcquisitionDate"];
		[imageObject setAttributeValues:[NSMutableArray array] forName:@"AcquisitionTime"];
	}
	/*
	if ([fetchedObject valueForKey:@"dicomDate"]){
		NSNumber *dateNumber = [fetchedObject valueForKey:@"dicomDate"];
		NSString *dateString = [NSString stringWithFormat:@"%d", [dateNumber intValue]];
		[imageObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDate:dateString]] forName:@"AcquisitionDate"];
	}
	else
		[imageObject setAttributeValues:[NSMutableArray array] forName:@"AcquisitionDate"];
		
	if ([fetchedObject valueForKey:@"dicomTime"]){
		NSNumber *dateNumber = [fetchedObject valueForKey:@"dicomTime"];
		NSString *dateString = [NSString stringWithFormat:@"%d", [dateNumber intValue]];
		[imageObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTime:dateString]] forName:@"AcquisitionTime"];
	}
	else
		[imageObject setAttributeValues:[NSMutableArray array] forName:@"AcquisitionTime"];
	*/	
	if ([fetchedObject valueForKey:@"instanceNumber"])
		[imageObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"instanceNumber"]] forName:@"InstanceNumber"];
	else
		[imageObject setAttributeValues:[NSMutableArray array] forName:@"InstanceNumber"];
			
	if ([fetchedObject valueForKey:@"sopInstanceUID"])
		[imageObject setAttributeValues:[NSMutableArray arrayWithObject:[fetchedObject valueForKey:@"sopInstanceUID"]] forName:@"SOPInstanceUID"];

	return imageObject;
}

-(NSTimeInterval) endOfDay:(NSCalendarDate *)day
{
	NSCalendarDate *start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L];
	NSCalendarDate *end = [start dateByAddingYears:0 months:0 days:0 hours:24 minutes:0 seconds:0];
	return [end timeIntervalSinceReferenceDate];
}

-(NSTimeInterval) startOfDay:(NSCalendarDate *)day
{
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L];
	return [start timeIntervalSinceReferenceDate];
}
@end
