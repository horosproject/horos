//
//  DCMTKDataHandlerCategory.h
//  OsiriX
//
//  Created by Lance Pysher on 3/23/06.

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
#import "OsiriXSCPDataHandler.h"

#undef verify
#include "dcdatset.h"
#include "ofcond.h"

@interface OsiriXSCPDataHandler (DCMTKDataHandlerCategory)


- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset;
- (void)studyDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset;
- (void)seriesDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset;
- (void)imageDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset;

- (OFCondition)prepareFindForDataSet:( DcmDataset *)dataset;
- (OFCondition)prepareMoveForDataSet:( DcmDataset *)dataset;

- (BOOL)findMatchFound;
- (BOOL)moveMatchFound;

- (OFCondition)nextFindObject:(DcmDataset *)dataset  isComplete:(BOOL *)isComplete;
- (OFCondition)nextMoveObject:(DcmDataset *)dataset;

 
@end
