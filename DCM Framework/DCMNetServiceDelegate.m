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

#import "DCMNetServiceDelegate.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static DCMNetServiceDelegate *_netServiceDelegate = 0L;
static NSHost *currentHost = 0L;
static BOOL bugFixedForDNSResolve = NO;
static NSMutableArray *cachedServersArray = 0L;
static NSLock *currentHostLock = 0L;

@implementation DCMNetServiceDelegate

+ (id)sharedNetServiceDelegate
{
	if (! _netServiceDelegate)
		_netServiceDelegate = [[DCMNetServiceDelegate alloc] init];
	return _netServiceDelegate;
}

+(NSHost*) currentHost
{
	if( currentHost == 0L)
	{
		if( currentHostLock == 0L) currentHostLock = [[NSLock alloc] init];
		
		[currentHostLock lock];
		currentHost = [[NSHost currentHost] retain];
		[currentHostLock unlock];
	}
	
	return currentHost;
}

- (void) setPublisher: (NSNetService*) p
{
	publisher = p;
}

- (id)init{

	if (self = [super init])
	{
		OSErr err;
		SInt32 osVersion;
		
		err = Gestalt ( gestaltSystemVersion, &osVersion );       
		if ( err == noErr)       
		{
			if ( osVersion >= 0x1052UL ) bugFixedForDNSResolve = YES;
		}
		
		#if !__LP64__
			bugFixedForDNSResolve = YES;
		#endif
		
		_dicomNetBrowser = [[NSNetServiceBrowser alloc] init];
		[_dicomNetBrowser setDelegate:self];
		[self update];
	}
	return self;
}

- (void)update
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])
	{
		NSLog(@"searchDICOMBonjour - searchForServicesOfType : _dicom._tcp");
		[_dicomNetBrowser searchForServicesOfType:@"_dicom._tcp." inDomain:@""];
	}
}

- (void)dealloc
{
	NSLog(@"DCMNetServiceDelegate dealloc");
	[_dicomServices release];
	[_dicomNetBrowser release];
	[super dealloc];
	
}

- (NSArray *)dicomServices{
	return _dicomServices;
}

- (int)portForNetService:(NSNetService *)netService
{		
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

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	if( aNetService == publisher || [[aNetService name] isEqualToString: [publisher name]] == YES)
	{
	
	}
	else if( [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])
	{
		if( bugFixedForDNSResolve)
		{
			[_dicomServices addObject: aNetService];
			
			[aNetService resolveWithTimeout: 5];
			[aNetService setDelegate:self];
		}
	}
}

//Bonjour Delegate methods
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
	NSLog(@"netServiceBrowser didNotSearch");	
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	[aNetService retain];	// <- Yes, this is a memory leak, but we will avoid a not comprehensible bug....
	
	if( [_dicomServices containsObject: aNetService])
	{
		NSLog( @"didRemove retainCout: %d", [aNetService retainCount]);
		[_dicomServices removeObject: aNetService];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMNetServicesDidChange" object:nil];
	}
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
    NSLog( @"There was an error while attempting to resolve address for %@", [sender name]);
}

+ (NSArray *) DICOMServersListSendOnly: (BOOL) send QROnly:(BOOL) QR cached:(BOOL) cached
{
	NSMutableArray *serversArray = 0L;
	
	if( cached == NO)	// Important - forked processes will fail here
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncDICOMNodes"])
		{
			NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncDICOMNodesURL"]];
			
			if( url)
			{
				NSArray	*r = [NSArray arrayWithContentsOfURL: url];
				
				if( r)
					[[NSUserDefaults standardUserDefaults] setObject: r forKey:@"SERVERS"];
			}
		}
	}
	
	if( cached == NO || cachedServersArray == 0L)
	{
		serversArray = [NSMutableArray arrayWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"]];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])
		{
			NSArray					*dicomServices		= [[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices];
			
			for( int i = 0 ; i < [dicomServices count] ; i++) {
				NSNetService*	aServer = [dicomServices objectAtIndex: i];
				
				NSString		*hostname;
				int				port;
				
				hostname = [DCMNetServiceDelegate gethostnameAndPort:&port forService: aServer];
				
				if( hostname) {
					[serversArray addObject: [NSDictionary dictionaryWithObjectsAndKeys:	hostname, @"Address",
																							[aServer name], @"AETitle",
																							[NSString stringWithFormat:@"%d", port], @"Port",
																							[NSNumber numberWithBool:YES] , @"QR",
																							[NSNumber numberWithBool:YES] , @"Send",
																							[NSString stringWithFormat:@"%@ (Bonjour)", [aServer hostName]], @"Description",
																							[NSNumber numberWithInt:0], @"Transfer Syntax",
																							0L]];
				}
			}
		}
		
		[cachedServersArray release];
		cachedServersArray = [[NSMutableArray arrayWithArray: serversArray] retain];
	}
	else serversArray = [NSMutableArray arrayWithArray: cachedServersArray];
	
	if( send) {
		for( int i = 0 ; i < [serversArray count] ; i++) {
			if( [[serversArray objectAtIndex: i] valueForKey:@"Send"] != 0L && [[[serversArray objectAtIndex: i] valueForKey:@"Send"] boolValue] == NO)
			{
				[serversArray removeObjectAtIndex: i];
				i--;
			}
		}
	}
	
	if( QR)	{
		for( int i = 0 ; i < [serversArray count] ; i++ ) {
			if( [[serversArray objectAtIndex: i] valueForKey:@"QR"] != 0L && [[[serversArray objectAtIndex: i] valueForKey:@"QR"] boolValue] == NO)
			{
				[serversArray removeObjectAtIndex: i];
				i--;
			}
		}
	}
	
	return serversArray;
}

+ (NSArray *) DICOMServersListSendOnly: (BOOL) send QROnly:(BOOL) QR
{
	return [DCMNetServiceDelegate DICOMServersListSendOnly:NO QROnly:NO cached:NO];
}

+ (NSArray *) DICOMServersList
{
	return [DCMNetServiceDelegate DICOMServersListSendOnly:NO QROnly:NO];
}

+ (NSString*) gethostnameAndPort: (int*) port forService:(NSNetService*) sender
{
	struct sockaddr		*result;
	char				buffer[256];
	NSString			*hostname = nil;
	NSString			*portString = nil;
	
	for ( NSData *addr in [sender addresses] ) {
		result = (struct sockaddr *)[addr bytes];
	
		int family = result->sa_family;
		if (family == AF_INET) {
			if (inet_ntop(AF_INET, &((struct sockaddr_in *)result)->sin_addr, buffer, sizeof(buffer))) {
				hostname = [NSString stringWithCString:buffer];
				portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)result)->sin_port)];
				
				//NSLog( @"%@:%@", hostname, portString);
				
				if(port) *port = [portString intValue];
			}
		}
		else if (family == AF_INET6)
		{
		
		}
		else
		{
		
		}
	}
	
	return hostname;
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog( @"DCMNetServiceDelegate netServiceDidResolveAddress: %@", [sender description]);
	
//	if( [[sender name] isEqualToString: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]] == NO || [[[DCMNetServiceDelegate currentHost] name] isEqualToString: [sender hostName]] == NO)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMNetServicesDidChange" object:nil];
	}
}
@end
