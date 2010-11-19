//
//  NSError+OsiriX.mm
//  OsiriX
//
//  Created by Alessandro Volz on 11/19/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSError+OsiriX.h"


@implementation NSError (OsiriX)

NSString* const OsirixErrorDomain = @"OsiriXDomain";

+(NSError*)osirixErrorWithCode:(NSInteger)code underlyingError:(NSError*)underlyingError localizedDescription:(NSString*)desc {
	return [NSError errorWithDomain:OsirixErrorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys: desc, NSLocalizedDescriptionKey, underlyingError, NSUnderlyingErrorKey, NULL]];
}

+(NSError*)osirixErrorWithCode:(NSInteger)code underlyingError:(NSError*)underlyingError localizedDescriptionFormat:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString* desc = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	return [self osirixErrorWithCode:code underlyingError:underlyingError localizedDescription:desc];
}

+(NSError*)osirixErrorWithCode:(NSInteger)code localizedDescription:(NSString*)desc {
	return [NSError errorWithDomain:OsirixErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)osirixErrorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString* desc = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	return [self osirixErrorWithCode:code localizedDescription:desc];
}

@end
