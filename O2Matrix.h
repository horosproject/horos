//
//  O2Matrix.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 02.11.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface O2Matrix : NSMatrix {
}

@end

@interface O2MatrixRepresentedObject : NSObject {
    id _object;
    NSArray* _children;
}

@property(retain) id object;
@property(retain) NSArray* children;

+ (id)object:(id)object;
+ (id)object:(id)object children:(NSArray*)children;

@end