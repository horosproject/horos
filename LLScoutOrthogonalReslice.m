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

#import "LLScoutOrthogonalReslice.h"


@implementation LLScoutOrthogonalReslice

- (void) reslice : (long) x : (long) y
{
	[self xReslice:y];
}

- (void) yReslice: (long) y{}

- (NSMutableArray*) yReslicedDCMPixList
{
	return originalDCMPixList;
}

@end
