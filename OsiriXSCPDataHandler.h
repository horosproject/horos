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

typedef struct
{
	char logPatientName[ 1024];
	char logStudyDescription[ 1024];
	char logCallingAET[ 1024];
	time_t logStartTime;
	char logMessage[ 1024];
	char logUID[ 1024];
	long logNumberReceived;
	long logNumberTotal;
	time_t logEndTime;
	char logType[ 1024];
	char logEncoding[ 1024];
} logStruct;

#import <Cocoa/Cocoa.h>
#import <OsiriX/DCM.h>

#undef verify
#include "dcdatset.h"
#include "ofcond.h"

//NSString * const OsiriXFileReceivedNotification;

/** \brief  Finds the appropriate study/series/image for Q/R
*
* Finds the appropriate study/series/image for Q/R
* Interface between server and database 
*/

@interface OsiriXSCPDataHandler : NSObject
{
	NSArray *findArray;
	NSString *specificCharacterSet;
	NSEnumerator *findEnumerator;
	NSString *callingAET;
	NSManagedObjectContext *context;
	
	int numberMoving;
	
	NSStringEncoding encoding;
	int moveArrayEnumerator;
	int moveArraySize;
	char **moveArray;
	logStruct *logFiles;
	
	NSMutableDictionary *findTemplate;
}

@property (retain) NSString *callingAET;

+ (id)allocRequestDataHandler;

-(NSTimeInterval)endOfDay:(NSCalendarDate *)day;
-(NSTimeInterval)startOfDay:(NSCalendarDate *)day;

- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset compressedSOPInstancePredicate: (NSPredicate**) csopPredicate seriesLevelPredicate: (NSPredicate**) SLPredicate;
- (void)studyDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset;
- (void)seriesDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset;
- (void)imageDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset;

- (OFCondition)prepareFindForDataSet:( DcmDataset *)dataset;
- (OFCondition)prepareMoveForDataSet:( DcmDataset *)dataset;

- (BOOL)findMatchFound;
- (int)moveMatchFound;

- (OFCondition)nextFindObject:(DcmDataset *)dataset  isComplete:(BOOL *)isComplete;
- (OFCondition)nextMoveObject:(char *)imageFileName;
@end
