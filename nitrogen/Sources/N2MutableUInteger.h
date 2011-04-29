//
//  N2MutableInteger.h
//  OsiriX
//
//  Created by Alessandro Volz on 05.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface N2MutableUInteger : NSObject {
	NSUInteger _value;
}

+(id)mutableUIntegerWithUInteger:(NSUInteger)value;

@property NSUInteger unsignedIntegerValue;

-(id)initWithUInteger:(NSUInteger)value;

-(void)increment;

@end
