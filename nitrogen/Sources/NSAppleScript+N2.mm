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

#import "NSAppleScript+N2.h"
#import "NSAppleEventDescriptor+N2.h"
#import "N2Debug.h"


@implementation NSAppleScript (N2)

-(id)runWithArguments:(NSArray*)args error:(NSDictionary**)errs {
    if (!args)
        args = [NSArray array];
    
    NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass eventID:kAEOpenApplication targetDescriptor:nil returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    [event setDescriptor:[args appleEventDescriptor] forKeyword:keyDirectObject];
    
    NSAppleEventDescriptor* r = nil;
    
    @try {
        r = [self executeAppleEvent:event error:errs];
    }
    @catch (NSException *e) {
        N2LogExceptionWithStackTrace( e);
    }
    
    return [r object];
}

@end
