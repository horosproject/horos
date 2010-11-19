//
//  NSError+OsiriX.h
//  OsiriX
//
//  Created by Alessandro Volz on 11/19/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSError (OsiriX)

extern NSString* const OsirixErrorDomain;

+(NSError*)osirixErrorWithCode:(NSInteger)code localizedDescription:(NSString*)desc;
+(NSError*)osirixErrorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString*)format, ...;
+(NSError*)osirixErrorWithCode:(NSInteger)code underlyingError:(NSError*)underlyingError localizedDescription:(NSString*)desc;
+(NSError*)osirixErrorWithCode:(NSInteger)code underlyingError:(NSError*)underlyingError localizedDescriptionFormat:(NSString*)format, ...;

@end
