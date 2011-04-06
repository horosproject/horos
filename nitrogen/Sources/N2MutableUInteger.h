//
//  N2MutableInteger.h
//  OsiriX
//
//  Created by Alessandro Volz on 05.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface N2MutableUInteger : NSObject {
	NSUInteger value;
}

@property NSUInteger value;

-(id)initWithValue:(NSUInteger*)v;

-(void)increment;

@end
