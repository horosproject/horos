//
//  N2MutableInteger.mm
//  OsiriX
//
//  Created by Alessandro Volz on 05.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "N2MutableUInteger.h"


@implementation N2MutableUInteger

@synthesize unsignedIntegerValue = _value;

+(id)mutableUIntegerWithUInteger:(NSUInteger)value {
	return [[[[self class] alloc] initWithUInteger:value] autorelease];
}

-(id)initWithUInteger:(NSUInteger)value {
	if ((self = [super init])) {
		_value = value;
	}
	
	return self;
}

-(void)increment {
	++_value;
}

-(void)decrement {
	if (_value) --_value;
}

@end
