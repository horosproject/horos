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

extern NSString* N2ConnectionListenerOpenedConnectionNotification;
extern NSString* N2ConnectionListenerOpenedConnection;

@class N2Connection;

@interface N2ConnectionListener : NSObject  {
	Class _class;
    CFSocketRef ipv4socket;
    CFSocketRef ipv6socket;	
	NSMutableArray* _clients;
    BOOL _threadPerConnection;
}

@property BOOL threadPerConnection;

- (id)initWithPort:(NSInteger)port connectionClass:(Class)classs;
- (id)initWithPath:(NSString*)path connectionClass:(Class)classs;

- (in_port_t)port;

@end
