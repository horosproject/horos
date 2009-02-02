/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "KeywordsArrayController.h"


@implementation KeywordsArrayController

- (IBAction)addOrRemove:(id)sender{
	if ([sender selectedSegment] == 0)
		[self add:sender];
	else
		[self remove:sender];
}

@end
