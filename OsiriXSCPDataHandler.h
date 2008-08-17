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



typedef struct
{
	char logPatientName[ 1024];
	char logStudyDescription[ 1024];
	char logCallingAET[ 1024];
	time_t logStartTime;
	char logMessage[ 1024];
	char logUID[ 1024];
	int logNumberReceived;
	int logNumberTotal;
	time_t logEndTime;
	char logType[ 1024];
	char logEncoding[ 1024];
} logStruct;


#import <Cocoa/Cocoa.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>

//NSString * const OsiriXFileReceivedNotification;

/** \brief  Finds the appropriate study/series/image for Q/R
*
* Finds the appropriate study/series/image for Q/R
* Interface between server and database 
*/

@interface OsiriXSCPDataHandler : DCMCStoreReceivedPDUHandler
{
	NSArray *findArray;
	NSString *specificCharacterSet;
	NSEnumerator *findEnumerator;
	
	int numberMoving;
	
	NSStringEncoding encoding;
	int moveArrayEnumerator;
	int moveArraySize;
	char **moveArray;
	logStruct *logFiles;
}

+ (id)requestDataHandlerWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;

- (NSPredicate *)predicateForObject:(DCMObject *)dcmObject;
- (DCMObject *)studyObjectForFetchedObject:(id)fetchedObject;
- (DCMObject *)seriesObjectForFetchedObject:(id)fetchedObject;
- (DCMObject *)imageObjectForFetchedObject:(id)fetchedObject;

-(NSTimeInterval)endOfDay:(NSCalendarDate *)day;
-(NSTimeInterval)startOfDay:(NSCalendarDate *)day;


@end
