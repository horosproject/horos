//
//  NSMutableString+N2.mm
//  OsiriX
//
//  Created by Alessandro Volz on 11/3/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSMutableString+N2.h"
#import "NSString+N2.h"


@implementation NSMutableString (N2)

-(NSUInteger)replaceOccurrencesOfString:(NSString*)target withString:(NSString*)replacement {
	return [self replaceOccurrencesOfString:target withString:replacement options:NSLiteralSearch range:self.range];
}

@end
