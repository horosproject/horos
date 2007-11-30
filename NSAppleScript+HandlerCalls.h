/*

NSAppleScript+HandlerCalls.h
ASHandlerTest
by Buzz Andersen

More information at: http://www.scifihifi.com/weblog/mac/Cocoa-AppleEvent-Handlers.html

This work is licensed under the Creative Commons Attribution License. To view a copy of this license, visit

http://creativecommons.org/licenses/by/1.0/

or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford,
California 94305, USA.

*/

#import <Foundation/Foundation.h>

@interface NSAppleScript (HandlerCalls)

- (NSAppleEventDescriptor *) callHandler: (NSString *) handler withArguments: (NSAppleEventDescriptor *) arguments errorInfo: (NSDictionary **) errorInfo;

@end
