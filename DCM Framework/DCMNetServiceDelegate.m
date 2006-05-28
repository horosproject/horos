//
//  DCMNetServiceDelegate.m
//  OsiriX
//
//  Created by Lance Pysher on 7/13/05.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMNetServiceDelegate.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

DCMNetServiceDelegate *_netServiceDelegate;


@implementation DCMNetServiceDelegate

+ (id)sharedNetServiceDelegate{
	if (! _netServiceDelegate)
		_netServiceDelegate = [[DCMNetServiceDelegate alloc] init];
	return _netServiceDelegate;
}

- (id)init{
	if (self = [super init]){
		_dicomNetBrowser = [[NSNetServiceBrowser alloc] init];
		[_dicomNetBrowser setDelegate:self];
		[self update];		
	}
	return self;
}

- (void)update{
	[_dicomNetBrowser searchForServicesOfType:@"_dicom._tcp." inDomain:@""];
}

- (void)dealloc{
	[_dicomServices release];
	[_dicomNetBrowser release];
	[super dealloc];
	
}

- (NSArray *)dicomServices{
	return _dicomServices;
}

- (int)portForNetService:(NSNetService *)netService{
		
		//NSArray *addresses = [[_dicomServices objectAtIndex:0] addresses];
		NSArray *addresses = [netService addresses];
		NSLog( @"portForNetService addresses:%d", [addresses count]);
		struct sockaddr *addr = ( struct sockaddr *) [[addresses objectAtIndex:0]  bytes];
		int aPort = -1;
		if(addr->sa_family == AF_INET)		
			aPort = ((struct sockaddr_in *)addr)->sin_port;
		
		else if(addr->sa_family == AF_INET6)		
			aPort = ((struct sockaddr_in6 *)addr)->sin6_port;
				
		return NSSwapBigShortToHost(aPort);
}

//Bonjour Delegate methods

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	[aNetService setDelegate:self];
	[aNetService resolveWithTimeout:5];
}

//Bonjour Delegate methods
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict{
	NSLog(@"netServiceBrowser didNotSearch");
	
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
	[_dicomServices removeObject:aNetService];
	[[NSNotificationCenter defaultCenter] 	postNotificationName:@"DCMNetServicesDidChange" object:nil];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
	NSLog(@"Stopped DICOM bonjour search");
	[_dicomServices removeAllObjects];
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
	NSLog(@"Start bonjour DICOM search");
	if (_dicomServices)
		[_dicomServices release];
	_dicomServices = [[NSMutableArray array] retain];
}

//NetService delegate
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog( @"There was an error while attempting to resolve address for %@", [sender name] );
	[_dicomServices removeObject:sender];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog( [sender name]);
	if( [[sender name] isEqualToString: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]] == NO || [[NSHost currentHost] isEqualToHost: [NSHost hostWithName:[sender hostName]]] == NO)
	{
		[_dicomServices addObject: sender];
		[[NSNotificationCenter defaultCenter] 	postNotificationName:@"DCMNetServicesDidChange" object:nil];
		NSLog( @"Successfully resolved address for %@ at %@.", [sender name] , [sender hostName]);
	}
}
@end
