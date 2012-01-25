//
//  CSMailMailClient.h
//  CSMail
//
//  Created by Alastair Houghton on 27/01/2006.
//  Copyright 2006 Coriolis Systems Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
  kCSMCMessageDispatchFeature = 0x0001,
  kCSMCMessageConstructionFeature = 0x0002,
  kCSMCConfigureFeature = 0x0004,
};


@interface CSMailMailClient : NSObject
{
    NSAppleScript *script;
    NSDictionary *defaultSMTPAccount;
    NSString *fromAddress;
}

+ (id) mailClient;
- (NSString *)name;
- (NSString *)version;
- (NSDictionary *) defaultSMTPAccountFromMail;
- (NSString *)applicationName;

- (BOOL)applicationIsInstalled;
- (NSImage *)applicationIcon;

- (int)features;

- (BOOL)deliverMessage:(NSString *)messageBody
	       headers:(NSDictionary *)messageHeaders;
- (BOOL)deliverMessage:(NSString *)messageBody
               headers:(NSDictionary *)messageHeaders
           withMailApp:(BOOL) mailApp;

@end
