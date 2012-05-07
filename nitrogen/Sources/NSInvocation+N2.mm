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
            char v = [o charValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'i': {
            int v = [o integerValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 's': {
            short v = [o shortValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'l': {
            long v = [o longValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'q': {
            long long v = [o longLongValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'C': {
            unsigned char v = [o unsignedCharValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'I': {
            unsigned int v = [o unsignedIntegerValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'S': {
            unsigned short v = [o unsignedShortValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'L': {
            unsigned long v = [o unsignedLongValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'Q': {
            unsigned long long v = [o unsignedLongLongValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'f': {
            float v = [o floatValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'd': {
            double v = [o doubleValue];
            [self setArgument:&v atIndex:i];
		} break;
        case 'B': {
            bool v = [o boolValue];
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
