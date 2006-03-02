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



#import <Foundation/Foundation.h>
#import "DICOMQuery.h"

//@class PMAttributeList;
//@class PMDirectoryRecord;
@interface DICOMQueryStudyRoot: DICOMQuery {

//PMAttributeList *filterList;
NSMutableArray *queryList;

}

-(NSDictionary *)createRecord:(PMDirectoryRecord *)record;
- (void)createQueryList;
- (NSMutableArray *)queryList;
- (void) sortQueryList:(NSArray *)sortDescriptors;

@end
