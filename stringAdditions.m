//
//  stringAdditions.m
//  OsiriX
//
//  Created by joris on 22/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "stringAdditions.h"

@implementation NSString (stringAdditions)

- (NSComparisonResult)caseInsensitiveCompare:(NSString *)aString;
{
	return [self compare:aString options:NSCaseInsensitiveSearch];
}

- (NSComparisonResult)numericCompare:(NSString *)aString
{
	return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@end
