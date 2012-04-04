//
//  NSScreen+N2.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 03.04.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScreen (N2)

-(NSUInteger)screenNumber;
-(NSString*)displayName;
-(NSNumber*)serialNumber;

@end
