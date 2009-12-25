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
}

+ (id) mailClient;
- (NSString *)name;
- (NSString *)version;

- (NSString *)applicationName;

- (BOOL)applicationIsInstalled;
- (NSImage *)applicationIcon;

- (int)features;

- (BOOL)deliverMessage:(NSAttributedString *)messageBody
	       headers:(NSDictionary *)messageHeaders;
- (BOOL)constructMessage:(NSAttributedString *)messageBody
		 headers:(NSDictionary *)messageHeaders;

@end
