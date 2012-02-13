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

#import <Cocoa/Cocoa.h>


@interface N2XMLRPC : NSObject {
}

enum N2XMLRPCOptionMasks {
    N2XMLRPCDontSpecifyStringTypeOptionMask = 1<<0
};

+(NSObject*)ParseElement:(NSXMLNode*)n;
+(NSString*)FormatElement:(NSObject*)o;
+(NSString*)FormatElement:(NSObject*)o options:(NSUInteger)options;

+(NSString*)requestWithMethodName:(NSString*)methodName arguments:(NSArray*)args;
+(NSString*)responseWithValue:(id)value;
+(NSString*)responseWithValue:(id)value options:(NSUInteger)options;

@end
