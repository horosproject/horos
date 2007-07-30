//
//  DCMSocket.h
//  OsiriX
//
//  Created by Lance Pysher on 6/8/05.

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
//

#import <Cocoa/Cocoa.h>


@interface NSFileHandle (DCMSocket)
/*
@interface DCMSocket : NSObject {
	

}
*/
- (id)initWithNetService:(NSNetService *)netService;
- (id)initWithAddress:(NSData *)addr;
- (id)initWithHostname:(NSString *)hostname port:(unsigned short)port;
- (id)initWithPort:(unsigned short)port numberOfConnection:(int)numberOfConnections;
- (int)newSocket;
+ (int)serverSocketForPort:(unsigned short)port;


@end
