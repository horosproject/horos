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
#include <sstream>

@implementation NSInvocation (N2)

+(NSInvocation*)invocationWithSelector:(SEL)sel target:(id)target {
    return [[self class] invocationWithSelector:sel target:target argument:nil];
}

+(NSInvocation*)invocationWithSelector:(SEL)selector target:(id)target argument:(id)arg {
	NSMethodSignature* signature = [target methodSignatureForSelector:selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
	invocation.target = target;
	invocation.selector = selector;
	if (arg) [invocation setArgumentObject:arg atIndex:2];
	return invocation;
}

// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html

-(void)setArgumentObject:(id)o atIndex:(NSUInteger)i {
	const char* argumentType = [self.methodSignature getArgumentTypeAtIndex:i];
    switch (argumentType[0]) {
		case '@': {
			[self setArgument:&o atIndex:i];
		} break;
        case 'c': {
            char v = [o isKindOfClass:[NSString class]]? strtol([o UTF8String], NULL, 0) : [o charValue]; // string converted to long, then to char
            [self setArgument:&v atIndex:i];
		} break;
        case 'i': {
            int v = [o integerValue]; // is NSString-safe
            [self setArgument:&v atIndex:i];
		} break;
        case 's': {
            short v = [o isKindOfClass:[NSString class]]? strtol([o UTF8String], NULL, 0) : [o shortValue]; // string converted to long, then to short
            [self setArgument:&v atIndex:i];
		} break;
        case 'l': {
            long v = [o isKindOfClass:[NSString class]]? strtol([o UTF8String], NULL, 0) : [o longValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'q': {
            long long v = [o longLongValue]; // is NSString-safe
            [self setArgument:&v atIndex:i];
		} break;
        case 'C': {
            unsigned char v = [o isKindOfClass:[NSString class]]? strtol([o UTF8String], NULL, 0) : [o unsignedCharValue]; // string converted to long, then to unsigned char
            [self setArgument:&v atIndex:i];
		} break;
        case 'I': {
            unsigned int v = [o isKindOfClass:[NSString class]]? strtol([o UTF8String], NULL, 0) : [o unsignedIntegerValue]; // string converted to long, then to unsigned int
            [self setArgument:&v atIndex:i];
		} break;
        case 'S': {
            unsigned short v = [o isKindOfClass:[NSString class]]? strtol([o UTF8String], NULL, 0) : [o unsignedShortValue]; // string converted to long, then to unsigned short
            [self setArgument:&v atIndex:i];
		} break;
        case 'L': {
            unsigned long v = [o isKindOfClass:[NSString class]]? strtoul([o UTF8String], NULL, 0) : [o unsignedLongValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'Q': {
            unsigned long long v = [o isKindOfClass:[NSString class]]? strtoull([o UTF8String], NULL, 0) : [o unsignedLongLongValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'f': {
            float v = [o floatValue]; // is NSString-safe
            [self setArgument:&v atIndex:i];
		} break;
        case 'd': {
            double v = [o doubleValue]; // is NSString-safe
            [self setArgument:&v atIndex:i];
		} break;
        case 'B': {
            bool v = [o boolValue]; // is NSString-safe
            [self setArgument:&v atIndex:i];
		} break;
        case 'v': {
            NSLog(@"Warning: unexpected invocation argument of type void");
		} break;
        case '*': {
            const char* v = [[o stringValue] UTF8String];
            [self setArgument:&v atIndex:i];
		} break;
        default: {
            if ([o isKindOfClass:[NSValue class]] && !strcmp(argumentType, [o objCType])) {
                NSUInteger size;
                NSGetSizeAndAlignment(argumentType, &size, NULL);
                void* v = malloc(size);
                [o getValue:v];
                [self setArgument:v atIndex:i];
                free(v);
            } else
                NSLog(@"Warning: unhandled invocation argument type '%s'", argumentType);
        } break;
	}
}

-(id)returnValue {
    NSUInteger returnLength = [[self methodSignature] methodReturnLength];
    if (!returnLength)
        return nil;
    void* r = malloc(returnLength);
    [self getReturnValue:r];
    @try {
        const char* returnType = [[self methodSignature] methodReturnType];
        switch (returnType[0]) {
            case '@':
                return *(id*)r;
            case 'c':
                return [NSNumber numberWithChar:*(char*)r];
            case 'i':
                return [NSNumber numberWithInt:*(int*)r];
            case 's':
                return [NSNumber numberWithShort:*(short*)r];
            case 'l':
                return [NSNumber numberWithLong:*(long*)r];
            case 'q':
                return [NSNumber numberWithLongLong:*(long long*)r];
            case 'C':
                return [NSNumber numberWithUnsignedChar:*(unsigned char*)r];
            case 'I':
                return [NSNumber numberWithUnsignedInt:*(unsigned int*)r];
            case 'S':
                return [NSNumber numberWithUnsignedShort:*(unsigned short*)r];
            case 'L':
                return [NSNumber numberWithUnsignedLong:*(unsigned long*)r];
            case 'Q':
                return [NSNumber numberWithUnsignedLongLong:*(unsigned long long*)r];
            case 'f':
                return [NSNumber numberWithFloat:*(float*)r];
            case 'd':
                return [NSNumber numberWithDouble:*(double*)r];
            case 'B':
                return [NSNumber numberWithBool:*(bool*)r];
            case 'v':
                return nil;
            case '*':
                return [NSString stringWithCString:*(char**)r encoding:NSUTF8StringEncoding];
            default:
                return [NSValue valueWithBytes:r objCType:returnType];
        }
    } @catch (NSException* e) {
        @throw e;
    } @finally {
        free(r);
    }

    return nil;
}

@end
