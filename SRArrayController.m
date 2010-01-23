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

#import "SRArrayController.h"


@implementation SRArrayController

- (IBAction)chooseAction:(id)sender{
	// allows to use anNSSegmentedControl
	if ([sender selectedSegment] == 0)
		[self add:sender];
	else
		[self remove:sender];
}

@end
