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
