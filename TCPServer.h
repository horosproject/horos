/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

//NSString * const TCPServerErrorDomain;

typedef enum {
    kTCPServerCouldNotBindToIPv4Address = 1,
    kTCPServerCouldNotBindToIPv6Address = 2,
    kTCPServerNoSocketsAvailable = 3,
} TCPServerErrorCode;


/** \brief TCP Server for RIS intergration */

@interface TCPServer : NSObject {
@private
    id delegate;
    NSString *domain;
    NSString *name;
    NSString *type;
    uint16_t port;
    CFSocketRef ipv4socket;
    CFSocketRef ipv6socket;
    NSNetService *netService;
}

- (id)delegate;
- (void)setDelegate:(id)value;

- (NSString *)domain;
- (void)setDomain:(NSString *)value;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)type;
- (void)setType:(NSString *)value;

- (uint16_t)port;
- (void)setPort:(uint16_t)value;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
// called when a new connection comes in; by default, informs the delegate

@end

@interface TCPServer (TCPServerDelegateMethods)
- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
// if the delegate implements this method, it is called when a new  
// connection comes in; a subclass may, of course, change that behavior
@end

