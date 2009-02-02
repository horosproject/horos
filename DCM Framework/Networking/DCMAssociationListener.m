/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMAssociationListener.h"
#import "DCMAssociationResponder.h"
#import <OmniNetworking/OmniNetworking.h>


static int defaultMaximumLengthReceived = 16384;
static int defaultReceiveBufferSize = 65536;
//static int defaultSendBufferSize = 0;
static int defaultTimeout = 5000; // in milliseconds



@implementation DCMAssociationListener

+ (id)listenerWithParameters:(NSDictionary *)params{
	return [[[DCMAssociationListener alloc] initWithParameters:params] autorelease];
}

- (id)initWithParameters:(NSDictionary *)params{
	 if (self = [super init]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//NSException *exception = nil;
		NS_DURING
			debugLevel = 0;
			if ([params objectForKey:@"debugLevel"])
				debugLevel = [[params objectForKey:@"debugLevel"] intValue];
			port = [[params objectForKey:@"hostname"] intValue];
			calledAET = [[params objectForKey:@"calledAET"] retain];
			timeout = defaultTimeout;
			if ([params objectForKey:@"timeout"])
				timeout = [[params objectForKey:@"timeout"] intValue];
			maximumLengthReceived =	defaultMaximumLengthReceived;
			if ([params objectForKey:@"ourMaximumLengthReceived"])
				maximumLengthReceived = [[params objectForKey:@"ourMaximumLengthReceived"] intValue];
					
			receivedBufferSize = defaultReceiveBufferSize;
			if ([params objectForKey:@"receivedBufferSize"]){
				receivedBufferSize = [[params objectForKey:@"receivedBufferSize"] intValue];

			}
		NS_HANDLER
			[calledAET  release];
			[hostname release];
			[socket release];
			self = nil;
		NS_ENDHANDLER
		[NSThread detachNewThreadSelector:@selector(listen:) toTarget:self withObject:nil];
		[pool release];
	}
	return self;
}

- (void)spawnNewResponder:(NSDictionary *)params{
	NSAutoreleasePool *pool;
	pool = [[NSAutoreleasePool alloc] init];
	[DCMAssociationResponder associationResponderWithParameters:params];
	[pool release];
}

- (void)listen:(id)object{
	
	while (YES) {
		NSAutoreleasePool *pool;
        pool = [[NSAutoreleasePool alloc] init];
        ONTCPSocket *connectionTCPSocket = [socket acceptConnectionOnNewSocket];
		if (connectionTCPSocket) {
			NSMutableDictionary *params = [NSMutableDictionary dictionary];
			NSLog(@"Accepted connection from host %@", [connectionTCPSocket remoteAddressHost]);
			// maybe we should keep them in this thread?
			[NSThread detachNewThreadSelector:@selector(spawnNewResponder:) toTarget:self withObject:params];
		}
		[pool release];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
}
	
	

@end
