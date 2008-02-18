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





#import <Cocoa/Cocoa.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>

//NSString * const OsiriXFileReceivedNotification;

/** \brief  Finds the appropriate study/series/image for Q/R
*
* Finds the appropriate study/series/image for Q/R
* Interface between server and database 
*/

@interface OsiriXSCPDataHandler : DCMCStoreReceivedPDUHandler {
	int numberMoving;
	id logEntry;
	NSString *specificCharacterSet;
	NSStringEncoding encoding;
	NSArray *findArray;
	NSEnumerator *findEnumerator;
	NSString *tempMoveFolder;

	int moveArrayEnumerator;
	int moveArraySize;
	char **moveArray;
}

+ (id)requestDataHandlerWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;

- (NSPredicate *)predicateForObject:(DCMObject *)dcmObject;
- (DCMObject *)studyObjectForFetchedObject:(id)fetchedObject;
- (DCMObject *)seriesObjectForFetchedObject:(id)fetchedObject;
- (DCMObject *)imageObjectForFetchedObject:(id)fetchedObject;

-(NSTimeInterval)endOfDay:(NSCalendarDate *)day;
-(NSTimeInterval)startOfDay:(NSCalendarDate *)day;


@end
