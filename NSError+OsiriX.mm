/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

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
