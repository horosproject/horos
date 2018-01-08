/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
                return [NSString stringWithUTF8String:*(char**)r];
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
