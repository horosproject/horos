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

#import "N2ConnectionListener.h"
#import "N2Connection.h"
#import "N2Debug.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/un.h>

NSString* N2ConnectionListenerOpenedConnectionNotification = @"N2ConnectionListenerOpenedConnectionNotification";
NSString* N2ConnectionListenerOpenedConnection = @"N2ConnectionListenerOpenedConnection";

@implementation N2ConnectionListener

@synthesize threadPerConnection = _threadPerConnection;

-(void)handleNewConnectionFromAddress:(NSData*)addr inputStream:(NSInputStream*)istr outputStream:(NSOutputStream*)ostr {
	NSString* address = NULL;
	if (addr) {
		struct sockaddr* sa = (struct sockaddr*)[addr bytes];
		switch (sa->sa_family) {
			case AF_INET: {
                size_t len = INET_ADDRSTRLEN;
                char tmp[len];
				struct sockaddr_in* sain = (struct sockaddr_in*)sa;
				inet_ntop(sa->sa_family, &sain->sin_addr.s_addr, tmp, len);
				address = [NSString stringWithUTF8String:tmp];
			} break;
			case AF_INET6: {
                size_t len = INET6_ADDRSTRLEN;
                char tmp[len];
				struct sockaddr_in6* sain6 = (struct sockaddr_in6*)sa;
				inet_ntop(sa->sa_family, &sain6->sin6_addr, tmp, len);
				address = [NSString stringWithUTF8String:tmp];
			} break;
		}
	}
	
	DLog(@"Handling new connection from %@", address);
	
    if (_threadPerConnection)
        [self performSelectorInBackground:@selector(_threadHandleNewConnection:) withObject:[NSArray arrayWithObjects: istr, ostr, address, nil]];
    else {
        N2Connection* connection = [[[_class alloc] initWithAddress:address port:0 is:istr os:ostr] autorelease];
        
        @synchronized (_clients) {
            [_clients addObject:connection];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:N2ConnectionListenerOpenedConnectionNotification object:self userInfo:[NSDictionary dictionaryWithObject:connection forKey:N2ConnectionListenerOpenedConnection]];
    }
}

-(void)_threadHandleNewConnection:(NSArray*)args {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    N2Connection* c = nil;
    @try {
        NSInputStream* istr = [args objectAtIndex:0];
        NSOutputStream* ostr = [args objectAtIndex:1];
        NSString* address = [args objectAtIndex:2];
        
        c = [[_class alloc] initWithAddress:address port:0 is:istr os:ostr];
        
        @synchronized (_clients) {
            [_clients addObject:c];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:N2ConnectionListenerOpenedConnectionNotification object:self userInfo:[NSDictionary dictionaryWithObject:c forKey:N2ConnectionListenerOpenedConnection]];
        
        while (c.status != N2ConnectionStatusClosed) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [c release];
        [pool release];
    }
}

static void accept(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	N2ConnectionListener* listener = (N2ConnectionListener*)info;
	if (type != kCFSocketAcceptCallBack)
		return;
	
	CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data; // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle

	uint8_t name[SOCK_MAXADDRLEN];
	socklen_t namelen = sizeof(name);
	NSData* peer = NULL;
	if (0 == getpeername(nativeSocketHandle, (struct sockaddr*)name, &namelen))
		peer = [NSData dataWithBytes:name length:namelen];
	
//	DLog(@"Accepting connection from %@", peer);
	
	CFReadStreamRef readStream = NULL;
	CFWriteStreamRef writeStream = NULL;
	CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
	if (readStream && writeStream) {
		CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		[listener handleNewConnectionFromAddress:peer inputStream:(NSInputStream*)readStream outputStream:(NSOutputStream*)writeStream];
	} else
		close(nativeSocketHandle);
	
	if (readStream) CFRelease(readStream);
	if (writeStream) CFRelease(writeStream);
}

-(id)initWithPort:(NSInteger)port connectionClass:(Class)classs {
    
    self = [super init];
    
	_clients = [[NSMutableArray alloc] init];
	_class = classs;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusDidChange:) name:N2ConnectionStatusDidChangeNotification object:NULL];
	
	CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
	ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&accept, &socketCtxt);
	ipv6socket = CFSocketCreate(kCFAllocatorDefault, PF_INET6, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&accept, &socketCtxt);
	if (!ipv4socket || !ipv6socket)
    {
        [self autorelease];
		[NSException raise:NSGenericException format:@"Could not create listening sockets."];
	}
	int yes = 1;
	setsockopt(CFSocketGetNative(ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	setsockopt(CFSocketGetNative(ipv6socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	
	// set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons(port);
	addr4.sin_addr.s_addr = htonl(INADDR_ANY);
	NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
	
	if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, (CFDataRef)address4)) {
		//		if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv4Address userInfo:nil];
		if (ipv4socket) CFRelease(ipv4socket);
		if (ipv6socket) CFRelease(ipv6socket);
		ipv4socket = NULL;
		ipv6socket = NULL;
        [self autorelease];
		return nil;
	}
	
	if (0 == port) {
		// now that the binding was successful, we get the port number 
		// -- we will need it for the v6 endpoint and for the NSNetService
        port = [self port];
		NSLog(@"Warning: listening on port %d", (int)port);
	}
	
	// set up the IPv6 endpoint
	struct sockaddr_in6 addr6;
	memset(&addr6, 0, sizeof(addr6));
	addr6.sin6_len = sizeof(addr6);
	addr6.sin6_family = AF_INET6;
	addr6.sin6_port = htons(port);
	memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
	NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
	
	if (kCFSocketSuccess != CFSocketSetAddress(ipv6socket, (CFDataRef)address6)) {
		//	  if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv6Address userInfo:nil];
		if (ipv4socket) CFRelease(ipv4socket);
		if (ipv6socket) CFRelease(ipv6socket);
		ipv4socket = NULL;
		ipv6socket = NULL;
        [self autorelease];
		return nil;
	}
	
	// set up the run loop sources for the sockets
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
	CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4socket, 0);
	CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
	CFRelease(source4);
	
	CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv6socket, 0);
	CFRunLoopAddSource(cfrl, source6, kCFRunLoopCommonModes);
	CFRelease(source6);
	
	return self;
}

-(id)initWithPath:(NSString*)path connectionClass:(Class)classs {
    
    self = [super init];
    
	_clients = [[NSMutableArray alloc] init];
	_class = classs;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusDidChange:) name:N2ConnectionStatusDidChangeNotification object:NULL];
	
	CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
	ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_LOCAL, SOCK_STREAM, IPPROTO_IP, kCFSocketAcceptCallBack, (CFSocketCallBack)&accept, &socketCtxt);
	if (!ipv4socket)
    {
        [self autorelease];
		[NSException raise:NSGenericException format:@"Could not create listening socket."];
	}
    
	int yes = 1;
	setsockopt(CFSocketGetNative(ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	
	// set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
	struct sockaddr_un local;
	local.sun_family = AF_LOCAL;
	strncpy(local.sun_path, [path UTF8String], 103); local.sun_path[103] = 0;
	unlink(local.sun_path);
	NSData* address = [NSData dataWithBytes:&local length:sizeof(sockaddr_un)];
	
	if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, (CFDataRef)address)) {
		//		if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv4Address userInfo:nil];
		if (ipv4socket) CFRelease(ipv4socket);
		if (ipv6socket) CFRelease(ipv6socket);
		ipv4socket = NULL;
		ipv6socket = NULL;
        [self autorelease];
		return nil;
	}
	
	// set up the run loop sources for the sockets
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
	CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4socket, 0);
	CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
	CFRelease(source4);
	
	CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv6socket, 0);
	CFRunLoopAddSource(cfrl, source6, kCFRunLoopCommonModes);
	CFRelease(source6);
	
	return self;
}

-(void)connectionStatusDidChange:(NSNotification*)notification {
	N2Connection* connection = [notification object];
	switch ([connection status])
    {
		case N2ConnectionStatusClosed:
			[connection close];
			@synchronized (_clients) {
                [_clients removeObject:connection];
            }
			break;
            
        default:
        break;
	}
}

-(void)dealloc {
	DLog(@"[N2ConnectionListener dealloc]");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (ipv4socket) {
		CFSocketInvalidate(ipv4socket);
		CFRelease(ipv4socket);
	}
	
	if (ipv6socket) {
		CFSocketInvalidate(ipv6socket);
		CFRelease(ipv6socket);
	}
	
	[_clients release];
	
	[super dealloc];
}

- (in_port_t)port {
    NSData* addr = [(NSData *)CFSocketCopyAddress(ipv4socket) autorelease];
    struct sockaddr_in addr4;
    memcpy(&addr4, [addr bytes], [addr length]);
    return ntohs(addr4.sin_port);
}

@end
