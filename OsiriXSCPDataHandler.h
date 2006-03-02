//
//  OsiriXSCP.h
//  OsiriX
//
//  Created by Lance Pysher on 3/22/05.

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




#import <Cocoa/Cocoa.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>

//NSString * const OsiriXFileReceivedNotification;


@interface OsiriXSCPDataHandler : DCMCStoreReceivedPDUHandler {
	int numberMoving;
	id logEntry;

}

+ (id)requestDataHandlerWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;

- (NSPredicate *)predicateForObject:(DCMObject *)dcmObject;
- (DCMObject *)studyObjectForFetchedObject:(id)fetchedObject;
- (DCMObject *)seriesObjectForFetchedObject:(id)fetchedObject;
- (DCMObject *)imageObjectForFetchedObject:(id)fetchedObject;

-(NSTimeInterval)endOfDay:(DCMCalendarDate *)day;
-(NSTimeInterval)startOfDay:(DCMCalendarDate *)day;


@end
