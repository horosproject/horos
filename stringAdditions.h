//
//  stringAdditions.h
//  OsiriX
//
//  Created by joris on 22/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (stringAdditions)

- (NSComparisonResult)numericCompare:(NSString *)aString;

@end
