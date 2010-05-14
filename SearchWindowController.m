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




#import "SearchWindowController.h"


@implementation SearchWindowController

- (id)init{
	if (self = [super initWithWindowNibName:@"SearchWindow"])
		subviews = [[NSMutableArray array] retain];
	return self;
}

//- (IBAction)search:(id)sender{
//	if ([sender tag] == 0)
//		madeCriteria = NO;
//	else {
//		madeCriteria = YES;
//		[self createCriteria];
//	}
//	[NSApp stopModal];
//}

@end
