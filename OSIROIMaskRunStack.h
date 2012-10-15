//
//  OISROIMaskStack.h
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 9/25/12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSIROIMask.h"

@interface OSIROIMaskRunStack : NSObject
{
    NSData *_maskRunData;
    NSUInteger maskRunCount;
    NSUInteger _maskRunIndex;
    
    NSMutableArray *_maskRunArray;
}

- (id)initWithMaskRunData:(NSData *)maskRunData;

- (OSIROIMaskRun)currentMaskRun;
- (void)pushMaskRun:(OSIROIMaskRun)maskRun;
- (OSIROIMaskRun)popMaskRun;

- (NSUInteger)count;

@end
