//
//  NSAppleScript+N2.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 03.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAppleScript (N2)

-(NSAppleEventDescriptor*)runWithArguments:(NSArray*)args error:(NSDictionary**)errs;

@end
