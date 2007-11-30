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
