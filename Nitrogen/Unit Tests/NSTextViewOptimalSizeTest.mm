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

#import "NSTextViewOptimalSizeTest.h"
#import <Nitrogen/N2Operators.h>
#import <Nitrogen/NSTextView+N2.h>
#import <Nitrogen/NSView+N2.h>


@implementation NSTextViewOptimalSizeTest

-(void)testOptimalSize {
	NSTextView* view = [[NSTextView alloc] initWithSize:NSZeroSize];
	[view setString:@"Test."];
	
	NSSize os = [view optimalSize];
	[view setFrame:NSMakeRect(NSZeroPoint, os)];
	
	NSSize nos = [view optimalSizeForWidth:os.width+[view sizeAdjust].size.width];
	
	STAssertEquals(os.width, nos.width, @"Widths not matching: [view optimalSize] = %f and [view optimalSizeForWidth:%f] = %f", os.width, os.width+[view sizeAdjust].size.width, nos.width);
	
	[view release];
}

@end
