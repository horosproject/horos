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

#import "NSInvocation+N2.h"
//#include <sstream>

@implementation NSInvocation (N2)

+(NSInvocation*)invocationWithSelector:(SEL)sel target:(id)target argument:(id)arg {
	NSMethodSignature* signature = [target methodSignatureForSelector:sel];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setTarget:target];
	[invocation setSelector:sel];
	
	// http://17.254.2.129/mac/library/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
	const char* firstArgumentType = [signature getArgumentTypeAtIndex:2];
//	DLog(@"Creating invocation for [%@ %@(%c)%@]", [target className], NSStringFromSelector(sel), firstArgumentType[0], arg);
	switch (firstArgumentType[0]) {
		case '@': {
			[invocation setArgument:&arg atIndex:2];
		} break;
			
		case 'i':
		case 'Q':
		case 'f':
		case 'd':
		case 'c': {
			if ([arg isKindOfClass:[NSString class]] || [arg isKindOfClass:[NSNumber class]]) {
				switch (firstArgumentType[0]) {
					case 'i': {
						NSInteger i = [arg integerValue];
						[invocation setArgument:&i atIndex:2];
					} break;
					case 'Q': {
						long long Q = [arg longLongValue];
						[invocation setArgument:&Q atIndex:2];
					} break;
					case 'f': {
						CGFloat f = [arg floatValue];
						[invocation setArgument:&f atIndex:2];
					} break;
					case 'd': {
						double d = [arg doubleValue];
						[invocation setArgument:&d atIndex:2];
					} break;
					case 'c': {
						char c = [arg intValue];
						[invocation setArgument:&c atIndex:2];
					} break;
				}
			}
		} break;
		
		case 'I': {
			if ([arg isKindOfClass:[NSString class]]) {
				switch (firstArgumentType[0]) {
					case 'I': {
						NSUInteger I = [arg integerValue];
						[invocation setArgument:&I atIndex:2];
					} break;
				}
			} else if ([arg isKindOfClass:[NSNumber class]]) {
				switch (firstArgumentType[0]) {
					case 'I': {
						NSUInteger I = [arg unsignedIntegerValue];
						[invocation setArgument:&I atIndex:2];
					} break;
				}
			} else {
				NSLog(@"Warning: unhandled argument class %@", [arg className]);
				return NULL;
			}
		} break;
			
		default: {
			NSLog(@"Warning: unhandled first argument type '%s'", firstArgumentType);
			return NULL;
		} break;
	}
	
	return invocation;
}

@end
