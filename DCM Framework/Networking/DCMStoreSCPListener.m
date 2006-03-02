//
//  DCMStoreSCPListener.m
//  OsiriX
//
//  Created by Lance Pysher on 12/22/04.

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
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMStoreSCPListener.h"
#import "DCMStoreSCP.h"
#import "DCM.h"


#import "DCMSocket.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>



@implementation DCMStoreSCPListener

+ (id)listenWithParameters:(NSDictionary *)params{
	DCMStoreSCPListener *listener = [[[DCMStoreSCPListener alloc] initWithParameters:params] autorelease];
	[NSThread detachNewThreadSelector:@selector(listen:) toTarget:listener withObject:nil]; 
	return listener;	
}


- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init]){
		folder = nil;
		calledAET = nil;
		port = 0;
		listen = YES;
		if ([params objectForKey:@"folder"])
			folder = [[params objectForKey:@"folder"] retain];
		if ([params objectForKey:@"calledAET"])
			calledAET = [[params objectForKey:@"calledAET"] retain];
		if ([params objectForKey:@"port"])
			port = [[params objectForKey:@"port"] intValue];
		
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:socketListener];
	
	[folder release];
	[calledAET release];
	[callingAET release];
	[socketListener release];
	[netService stop];
	[netService release];
	[super dealloc];
}
	
- (void)listen:(id)object{
	
	listen = YES;
	int fdForListening = [NSFileHandle serverSocketForPort:port];
	if (fdForListening > -1)
	{
		[self initBonjour];
		
		while (listen)
		{
			int connectfd;
			if ( (connectfd = accept( fdForListening,  (struct sockaddr *)NULL, NULL )) < 0 )
			{
				perror("accept");
				NSLog(@"Failed receiving connection");
			}
			else
			{
				//NSLog(@"New Connection");
				NSFileHandle *socketHandle = [[NSFileHandle alloc] initWithFileDescriptor:connectfd  closeOnDealloc:YES];					
				[NSThread detachNewThreadSelector:@selector(newConnection:) toTarget:self withObject:socketHandle];
				[socketHandle release];
			}
		}			
	}
	
	NSLog(@"Listening is over");
}

- (void)stop
{
	[netService stop];
	listen = NO;
}

- (void)newConnection:(NSFileHandle *)socketHandle{
	[socketHandle retain];
	//[socketListener acceptConnectionInBackgroundAndNotify];	
	NSLog(@"new connection");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSFileHandle *socketHandle = [[note userInfo] objectForKey:@"NSFileHandleNotificationFileHandleItem"];
	NS_DURING 
	NSArray *objects = [NSArray arrayWithObjects:socketHandle, folder, calledAET, nil];
	NSArray *keys= [NSArray arrayWithObjects:@"socketHandle", @"folder", @"calledAET", nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[DCMStoreSCP runStoreSCP:params];
	NS_HANDLER
		 NSLog(@"Exception raised: %@", localException);
	NS_ENDHANDLER
	NSLog(@"end new connection thread");	
	[pool release];
	[socketHandle release];
	
}

- (void)connectionAccepted: (NSNotification *)note{
	NSLog(@"connection accepted");
	[self newConnection:[[note userInfo] objectForKey:NSFileHandleNotificationFileHandleItem]];
	//NSFileHandle *newSocket = [[note userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];	
}


//bonjour
- (void)initBonjour{
	if  (netService)
		[netService release];
	netService = [[NSNetService  alloc] initWithDomain:@"" type:@"_dicom._tcp." name:calledAET port:port];
	[netService setDelegate:self];
	[netService publish];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
}

- (void)netServiceDidPublish:(NSNetService *)sender{
	NSLog(@"netServiceDidPublish");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender{
}

- (void)netServiceDidStop:(NSNetService *)sender{
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data{
}

- (void)netServiceWillPublish:(NSNetService *)sender{
}

- (void)netServiceWillResolve:(NSNetService *)sender{
}


@end
