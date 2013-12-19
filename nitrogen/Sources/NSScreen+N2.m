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

#import "NSScreen+N2.h"
#import <IOKit/graphics/IOGraphicsLib.h>

@implementation NSScreen (N2)

// based on http://commanigy.com/blog/2011/1/14/how-to-get-display-name-from-nsscreen

-(NSUInteger)screenNumber {
    return [[[self deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
}

- (NSString*)displayName {
    io_service_t framebuffer = CGDisplayIOServicePort([self screenNumber]);
    NSDictionary* deviceInfo = [(NSDictionary*)IODisplayCreateInfoDictionary(framebuffer, kIODisplayOnlyPreferredName) autorelease];
    NSDictionary* localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
    if ([localizedNames count] > 0)
        return [[localizedNames allValues] objectAtIndex:0];
    
    return nil;
}

-(NSNumber*)serialNumber {
    io_service_t framebuffer = CGDisplayIOServicePort([self screenNumber]);
    NSDictionary* deviceInfo = [(NSDictionary*)IODisplayCreateInfoDictionary(framebuffer, kIODisplayOnlyPreferredName) autorelease];
    return [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplaySerialNumber]];
}

@end
