//
//  N2MutableInteger.mm
//  OsiriX
//
//  Created by Alessandro Volz on 05.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "N2MutableUInteger.h"


@implementation N2MutableUInteger

@synthesize value;

-(id)initWithValue:(NSUInteger)v {
	self = [super init];
	value = v;
	return self;
}

-(void)increment {
	++value;
}

@end
