//
//  DCMSocket.m
//  OsiriX
//
//  Created by Lance Pysher on 6/8/05.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMSocket.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>


//@implementation DCMSocket
@implementation NSFileHandle (DCMSocket)

- (id)initWithNetService:(NSNetService *)netService{
	int socketFD = -1;
	//NSLog(@"init WithNetService: %@", [netService hostName]);
	NSEnumerator *enumerator = [[netService addresses] objectEnumerator];
	NSData *addr;
	struct sockaddr *result;
	
	while (addr = [enumerator nextObject]) {
		 result = (struct sockaddr *)[addr bytes];
	
		int family = result->sa_family;
		if (family == AF_INET)
			NSLog(@"af_INET");
		else if (family == AF_INET6)
			NSLog(@"af_INET_6");
		else
			NSLog(@"family: %d", family);
		
		
		//socketFD = socket(result->ai_family, result->ai_socktype, 0);
		socketFD = socket( family, SOCK_STREAM, 0 );
		if (socketFD >  -1) {
			NSLog(@"Have socket");
			break;	
		}				
	
	}
	
		if (socketFD < 0) {
		NSLog(@"No socket");
		return nil;	
	}
	
	if ( connect(socketFD, [addr bytes], [addr length]) < 0 ) {
		NSLog(@"Failed connection");
		perror("connect");
		return nil;
	}
	
	return [self initWithFileDescriptor:socketFD closeOnDealloc:YES];
	
}
	
	

- (id)initWithAddress:(NSData *)addr {
	int socketFD = -1;
	
//	struct addrinfo *result = (struct addrinfo *)[addr bytes];
	
	//int family = result->ai_family;
	/*
	if (family == AF_INET)
		NSLog(@"af_INET");
	else if (family == AF_INET6)
		NSLog(@"af_INET_6");
	else
		NSLog(@"family: %d", family);
	*/
	
	
	//socketFD = socket(result->ai_family, result->ai_socktype, 0);
	socketFD = socket( AF_INET, SOCK_STREAM, 0 );
	if (socketFD > -1) {
		NSLog(@"No socket");
		return nil;	
	}
		
	if ( connect(socketFD, [addr bytes], [addr length]) < 0 ) {
		NSLog(@"Failed connection");
		perror("connect");
		return nil;
	}
			
	return [self initWithFileDescriptor:socketFD closeOnDealloc:YES];
}

- (id)initWithHostname:(NSString *)hostname port:(unsigned short)port{
	//NSString *ipAddress = nil;
	//NSLog(@"init With: %@ port: %d", hostname, port);
	int socketFD = -1;
	const char *myHostname;
    struct addrinfo hints;
    struct addrinfo *results, *result;
    int err;
	int family = 0;
    
    myHostname = [hostname cString];
    bzero(&hints, sizeof(hints));
	hints.ai_family = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
    //results = NULL;
	//NSLog(@"host lookup");
	NSString *portString  =[NSString stringWithFormat:@"%d", port];
    err = getaddrinfo(myHostname, [portString cString], &hints, &results);
    if (err != 0) {
        NSLog(@"error getting host");
		freeaddrinfo(results);
		return nil;
    }
	//else
	//	NSLog(@"Got host");
	//NSLog(@"newSocket");
    for(result = results; result; result = result->ai_next) {
		socketFD = socket(result->ai_family, result->ai_socktype, 0);
		family = result->ai_family;
		
		if (family == AF_INET && socketFD > -1) break;	// Antoine - By forcing only AF_INET, it works on my network...
		
//		if (socketFD > -1) 
//			break;
		//serverAddress = &result;
    }
   /*
   if (family == AF_INET)
		NSLog(@"af_INET");
	else if (family == AF_INET6)
		NSLog(@"af_INET_6");
	else
		NSLog(@"family: %d", family);
	*/

	
	if (socketFD < 0) {
		freeaddrinfo(results);
		return nil;
	}
	
	//try changing socket buffer size	
	//int window_size = 128 * 1024;   /* 128 kilobytes */
	/*
	setsockopt(socketFD, SOL_SOCKET, SO_SNDBUF,
         (char *) &window_size, sizeof(window_size));
	setsockopt(socketFD, SOL_SOCKET, SO_RCVBUF,
         (char *) &window_size, sizeof(window_size));
	*/
	//NSLog(@"connect");
	if ( connect(socketFD, result->ai_addr, result->ai_addrlen) < 0 ) {
		NSLog(@"Failed connection");
		perror("connect");
		freeaddrinfo(results);
		return nil;
	}
	freeaddrinfo(results);
	return [self initWithFileDescriptor:socketFD closeOnDealloc:YES];
}


- (id)initWithPort:(unsigned short)port numberOfConnection:(int)numberOfConnections{
	// Here, create the socket from socket calls, then set up an 

	/*
		int fdForListening = 0;
		struct sockaddr_in serverAddress;

		 
		//In order to use NSFileHandle's acceptConnectionInBackgroundAndNotify method, we need to create a file descriptor that is itself a socket, bind that socket, and then set it up for listening. At this point, it's ready to be handed off to acceptConnectionInBackgroundAndNotify.
	

	if ((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
		memset (&serverAddress, 0, sizeof (serverAddress));
		serverAddress.sin_family = AF_INET;
		serverAddress.sin_addr.s_addr = htonl (INADDR_ANY);
		serverAddress.sin_port = htons (port);
		bzero(&(serverAddress.sin_zero), 8);    // zero the rest of the struct 
		NSLog(@"socket %d", fdForListening);
		// let us re-use it if kernel still hanging on to it
		int val = 1;
		setsockopt (fdForListening, SOL_SOCKET, SO_REUSEADDR, &val, sizeof val);
		// fcntl(fdForListening, F_SETFL,  0x0);

		if (bind (fdForListening, (struct sockaddr *)&serverAddress, 
sizeof (serverAddress)) < 0) {
			perror("bind");
			close (fdForListening);
			fdForListening = -1;
			//return NO;
		}
		else {
			if (listen(fdForListening , 5) > 0)
				perror("listen");
		}

	}
	*/
	int fdForListening = [NSFileHandle serverSocketForPort:port];
	return [self initWithFileDescriptor:fdForListening closeOnDealloc:YES];
}

- (int)newSocket{
	int socketFD;
	
	if ((socketFD = socket( AF_INET, SOCK_STREAM, 0 )) < 0 ) {
		NSLog(@"Couldn't create socket");

	} 
	NSLog(@"new Socket %d", socketFD);	
	return socketFD;
}

+ (int)serverSocketForPort:(unsigned short)port{
	// Here, create the socket from socket calls, then set up an 


		int fdForListening = 0;
		struct sockaddr_in serverAddress;

		/* 
		In order to use NSFileHandle's acceptConnectionInBackgroundAndNotify method, we need to create a file descriptor that is itself a socket, bind that socket, and then set it up for listening. At this point, it's ready to be handed off to acceptConnectionInBackgroundAndNotify.
	*/

	if ((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
		memset (&serverAddress, 0, sizeof (serverAddress));
		serverAddress.sin_family = AF_INET;
		serverAddress.sin_addr.s_addr = htonl (INADDR_ANY);
		serverAddress.sin_port = htons (port);
		bzero(&(serverAddress.sin_zero), 8);    /* zero the rest of the 
struct */
		NSLog(@"socket %d", fdForListening);
		// let us re-use it if kernel still hanging on to it
		int val = 1;
		setsockopt (fdForListening, SOL_SOCKET, SO_REUSEADDR, &val, sizeof val);
		// fcntl(fdForListening, F_SETFL,  0x0);

		if (bind (fdForListening, (struct sockaddr *)&serverAddress, 
sizeof (serverAddress)) < 0) {
			perror("bind");
			close (fdForListening);
			fdForListening = -1;
			//return NO;
		}
		else {
			if (listen(fdForListening , 5) > 0)
				perror("listen");
		}

	}
			// Once we're here, we know bind must have returned, so we can start the listen
	return fdForListening;
}

@end
