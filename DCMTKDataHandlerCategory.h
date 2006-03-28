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

@interface OsiriXSCPDataHandler (DCMTKDataHandlerCategory)


- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset;
- ( DcmDataset)studyDatasetForFetchedObject:(id)fetchedObject;
- ( DcmDataset *)seriesDatasetForFetchedObject:(id)fetchedObject;
- ( DcmDataset *)imageDatasetForFetchedObject:(id)fetchedObject;
- ( NSArray *)foundEntities;

 
@end
