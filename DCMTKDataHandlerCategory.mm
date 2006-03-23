//
//  DCMTKDataHandlerCategory.mm
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

#import "DCMTKDataHandlerCategory.h"


@implementation OsiriXSCPDataHandler (DCMTKDataHandlerCategory)

- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset{
	return nil;
}
- ( DcmDataset *)studyDatasetForFetchedObject:(id)fetchedObject{
	return nil;
}
- ( DcmDataset *)seriesDatasetForFetchedObject:(id)fetchedObject{
	return nil;
}
- ( DcmDataset *)imageDatasetForFetchedObject:(id)fetchedObject{
	return nil;
}
- ( NSArray *)foundEntities{
	return nil;
}

@end
