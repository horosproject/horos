//
//  NSMutableString+N2.h
//  OsiriX
//
//  Created by Alessandro Volz on 11/3/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableString (N2)

-(NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement;

@end
