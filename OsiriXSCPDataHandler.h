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

@class DicomDatabase;

@interface OsiriXSCPDataHandler : NSObject
{
	NSArray *findArray;
	NSString *specificCharacterSet;
	NSEnumerator *findEnumerator;
    int findEnumeratorIndex;
	NSString *callingAET;
    
	NSManagedObjectContext *context;
	
	int numberMoving;
	
	NSStringEncoding encoding;
	int moveArrayEnumerator;
    NSArray *moveArray;
	NSMutableDictionary *logDictionary;
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
