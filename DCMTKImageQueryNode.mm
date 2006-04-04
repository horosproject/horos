//
//  DCMTKImageQueryNode.mm
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

#import "DCMTKImageQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>


@implementation DCMTKImageQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset{
	return [[[DCMTKImageQueryNode alloc] initWithDataset:(DcmDataset *)dataset] autorelease];
}

@end
