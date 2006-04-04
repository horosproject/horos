//
//  DCMTKStudyQueryNode.mm
//  OsiriX
//
//  Created by Lance Pysher on 4/4/06.

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

#import "DCMTKStudyQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>


@implementation DCMTKStudyQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset{
	return [[[DCMTKStudyQueryNode alloc] initWithDataset:(DcmDataset *)dataset] autorelease];
}

@end
