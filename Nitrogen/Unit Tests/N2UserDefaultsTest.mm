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

#import "N2UserDefaultsTest.h"
#import <Nitrogen/N2UserDefaults.h>

@implementation N2UserDefaultsTest

NSRect r = NSMakeRect(1,2,3,4);
const NSString* const TestRectDefaultsKey64 = @"TestRectDefaultsKey64";
const NSString* const TestRectDefaultsKey32 = @"TestRectDefaultsKey32";

-(N2UserDefaults*)defaults {
	return [N2UserDefaults defaultsForIdentifier:@"com.osirix.nitrogen.N2UserDefaultsTest"];
}

-(void)testWriteRect {
	N2UserDefaults* defaults = [self defaults];
	STAssertNotNil(defaults, @"defaults must not be NULL");
#ifdef __LP64__
//	[defaults setRect:r forKey:TestRectDefaultsKey64];
#else
//	[defaults setRect:r forKey:TestRectDefaultsKey32];
#endif
}

-(void)testReadRect {
	N2UserDefaults* defaults = [self defaults];
	STAssertNotNil(defaults, @"defaults must not be NULL");
	STAssertTrue(NSEqualRects(r, [defaults rectForKey:TestRectDefaultsKey32 default:r]), @"Read rect 32 bits failure");
	STAssertTrue(NSEqualRects(r, [defaults rectForKey:TestRectDefaultsKey64 default:r]), @"Read rect 64 bits failure");
}

@end
