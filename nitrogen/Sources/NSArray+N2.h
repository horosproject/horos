//
//  NSArray+N2.h
//  OsiriX
//
//  Created by Alessandro Volz on 14.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (N2)

-(NSArray*)splitArrayIntoArraysOfMinSize:(NSUInteger)chunkSize maxArrays:(NSUInteger)maxArrays;

@end
