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


#import "DebugTest.h"
#import <Nitrogen/N2Debug.h>

@implementation DebugTest

-(void)testDebug {
	DLog(@"First, initial status...");
	[N2Debug setActive:YES];
	DLog(@"Second, after [N2Debug setActive:YES]");
	[N2Debug setActive:NO];
	DLog(@"Last, after [N2Debug setActive:NO]");
}

@end
