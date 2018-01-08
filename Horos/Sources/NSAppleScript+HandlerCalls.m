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
/*

NSAppleScript+HandlerCalls.m
ASHandlerTest
by Buzz Andersen

More information at: http://www.scifihifi.com/weblog/mac/Cocoa-AppleEvent-Handlers.html

This work is licensed under the Creative Commons Attribution License. To view a copy of this license, visit

http://creativecommons.org/licenses/by/1.0/

or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford,
California 94305, USA.

*/

#import "NSAppleScript+HandlerCalls.h"

@implementation NSAppleScript (HandlerCalls)

- (NSAppleEventDescriptor *) callHandler: (NSString *) handler withArguments: (NSAppleEventDescriptor *) arguments errorInfo: (NSDictionary **) errorInfo {
    NSAppleEventDescriptor* event; 
    NSAppleEventDescriptor* targetAddress; 
    NSAppleEventDescriptor* subroutineDescriptor; 
    NSAppleEventDescriptor* result;

    /* This will be a self-targeted AppleEvent, so we need to identify ourselves using our process id */
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType: typeKernelProcessID bytes: &pid length: sizeof(pid)];
    
    /* Set up our root AppleEvent descriptor: a subroutine call (psbr) */
    event = [[NSAppleEventDescriptor alloc] initWithEventClass: 'ascr' eventID: 'psbr' targetDescriptor: targetAddress returnID: kAutoGenerateReturnID transactionID: kAnyTransactionID];
    
    /* Set up an AppleEvent descriptor containing the subroutine (handler) name */
    subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString: handler];
    [event setParamDescriptor: subroutineDescriptor forKeyword: 'snam'];

    /* Add the provided arguments to the handler call */
    [event setParamDescriptor: arguments forKeyword: keyDirectObject];
    
    /* Execute the handler */
    result = [self executeAppleEvent: event error: errorInfo];
    
    [targetAddress release];
    [event release];
    
    return result;
}

@end
