//
//  N2UserDefaultsTest.mm
//  Nitrogen
//
//  Created by Alessandro Volz on 1/27/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

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
