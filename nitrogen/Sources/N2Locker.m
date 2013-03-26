//
//  N2Locker.m
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 25.03.13.
//  Copyright (c) 2013 OsiriX Team. All rights reserved.
//

#import "N2Locker.h"

@implementation N2Locker

+ (id)lock:(id)lockedObject {
    return [[[self alloc] initWithLockedObject:lockedObject] autorelease];
}

- (id)initWithLockedObject:(id)lockedObject {
    if ((self = [super init])) {
        _lockedObject = [lockedObject retain];
        [_lockedObject lock];
    }
    
    return self;
}

- (void)dealloc {
    [_lockedObject unlock];
    [_lockedObject release];
    [super dealloc];
}

@end
