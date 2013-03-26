//
//  N2Locker.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 25.03.13.
//  Copyright (c) 2013 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface N2Locker : NSObject {
    id _lockedObject;
}

+ (id)lock:(id)lockedObject;

@end
