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

#include <netdb.h>
#import "DCMTKStoreSCU.h"
#import "BonjourBrowser.h"
#import "BrowserController.h"
#import "AppController.h"
#import "DicomFile.h"
#import "DicomImage.h"
#import "DCMNetServiceDelegate.h"
#import "Notifications.h"
#import "SendController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "NSUserDefaultsController+OsiriX.h"


@implementation BonjourBrowser

static BonjourBrowser *currentBrowser = nil;

+(BonjourBrowser*)currentBrowser {
	return currentBrowser;
}

-(id)initWithBrowserController:(BrowserController*)bC bonjourPublisher:(BonjourPublisher*)bPub {
	if ((self = [super init])) {
		OSErr err;       
		SInt32 osVersion;
		
		currentBrowser = self;
		
		browser = [[NSNetServiceBrowser alloc] init];
		services = [[NSMutableArray array] retain];
		
		[self buildFixedIPList];
		[self buildLocalPathsList];
		[self buildDICOMDestinationsList];
//		[[BrowserController currentBrowser] loadDICOMFromiPod];
		[self arrangeServices];
		
		interfaceOsiriX = bC;
		publisher = bPub;
		
		[browser setDelegate:self];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"] == NO)
			[browser searchForServicesOfType:@"_osirixdb._tcp." inDomain:@""];
		
//		[browser scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateFixedList:)
													 name: OsirixServerArrayChangedNotification
												   object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateFixedList:)
													 name: @"DCMNetServicesDidChange"
												   object: nil];
	}
	
	return self;
}

- (void) dealloc
{
	[browser release];
	[services release];
	
	[super dealloc];
}

- (NSMutableArray*) services
{
	return services;
}



- (void)showErrorMessage: (NSString*) s
{	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
	{
		NSAlert* alert = [[NSAlert new] autorelease];
		[alert setMessageText: NSLocalizedString(@"Network Error",nil)];
		[alert setInformativeText: s];
		[alert runModal];
	}
	else
		NSLog( @"*** Bonjour Browser Error (not displayed - hideListenerError): %@", s);
}

- (void) syncOsiriXDBList
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncOsiriXDBURL"]];
	
	if( url)
	{
		NSArray	*r = [NSArray arrayWithContentsOfURL: url];
		if( r)
			[[NSUserDefaults standardUserDefaults] setObject: r forKey: @"OSIRIXSERVERS"];
	}
	
	[pool release];
}

- (void) buildFixedIPList
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncOsiriXDB"])
	{
		[NSThread detachNewThreadSelector:@selector(syncOsiriXDBList) toTarget:self withObject:nil];
	}

	int			i;
	NSArray		*osirixServersArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"OSIRIXSERVERS"];
	
	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"fixedIP"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [osirixServersArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [osirixServersArray objectAtIndex: i]];
		[dict setValue:@"fixedIP" forKey:@"type"];
	
		[services addObject: dict];
	}
}

- (void) buildDICOMDestinationsList
{
	int			i;
	NSArray		*dbArray = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
	
	if( dbArray == nil) dbArray = [NSArray array];
	
	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"dicomDestination"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [dbArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [dbArray objectAtIndex: i]];
		
		[dict setValue:@"dicomDestination" forKey:@"type"];
		[services addObject: dict];
	}
}

- (void) buildLocalPathsList
{
	int			i;
	NSArray		*dbArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
	NSString	*defaultPath = documentsDirectoryFor( [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]);
	
	if( dbArray == nil) dbArray = [NSArray array];
	
	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"localPath"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [dbArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [dbArray objectAtIndex: i]];
		
		if( [[dict valueForKey:@"Path"] isEqualToString: defaultPath] == NO && [[[dict valueForKey:@"Path"] stringByAppendingPathComponent:@"OsiriX Data"] isEqualToString: defaultPath] == NO)
		{
			[dict setValue:@"localPath" forKey:@"type"];
			[services addObject: dict];
		}
	}
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) updateFixedList: (NSNotification*) note
{
	int i = [[BrowserController currentBrowser] currentBonjourService];
	
	NSDictionary	*selectedDict = nil;
	if( i >= 0) 
		selectedDict = [[services objectAtIndex: i] retain];
	
	[self buildFixedIPList];
	[self buildLocalPathsList];
	[[BrowserController currentBrowser] loadDICOMFromiPod];
	[self buildDICOMDestinationsList];
	[self arrangeServices];
	
	[interfaceOsiriX displayBonjourServices];
	
	if( selectedDict)
	{
		NSInteger index = [services indexOfObject: selectedDict];
		
		if( index == NSNotFound)
			[[BrowserController currentBrowser] resetToLocalDatabase];
		else
			[[BrowserController currentBrowser] setCurrentBonjourService: index];
		
		[selectedDict release];
	}
	
	[interfaceOsiriX displayBonjourServices];
}

- (void) arrangeServices
{
	// Order them, first the localPath, fixedIP, and then bonjour
	
	NSMutableArray	*result = [NSMutableArray array];
	int i;
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"localPath"])
			[result addObject: [services objectAtIndex: i]];
	}
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"fixedIP"])
			[result addObject: [services objectAtIndex: i]];
	}
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"bonjour"])
			[result addObject: [services objectAtIndex: i]];
	}
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"dicomDestination"])
			[result addObject: [services objectAtIndex: i]];
	}

	[services removeAllObjects];
	[services addObjectsFromArray: result];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————


- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
	   if ([[sender addresses] count] > 0)
	   {
			NSData * address;
			struct sockaddr * socketAddress;
			NSString * ipAddressString = nil;
			NSString * portString = nil;
			char buffer[256];
			int index;

			// Iterate through addresses until we find an IPv4 address
			for (index = 0; index < [[sender addresses] count]; index++)
			{
				address = [[sender addresses] objectAtIndex:index];
				socketAddress = (struct sockaddr *)[address bytes];

				if (socketAddress->sa_family == AF_INET) break;
			}

			// Be sure to include <netinet/in.h> and <arpa/inet.h> or else you'll get compile errors.

			if (socketAddress) {
				switch(socketAddress->sa_family) {
					case AF_INET:
						if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer))) {
							ipAddressString = [NSString stringWithCString:buffer];
							portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
						}
						
						// Cancel the resolve now that we have an IPv4 address.
						[sender stop];

						break;
					case AF_INET6:
						// OsiriX server doesn't support IPv6
						return;
				}
			}
			
			for( NSDictionary *serviceDict in services)
			{
				if( [serviceDict objectForKey:@"service"] == sender)
				{
					NSLog( @"netServiceDidResolveAddress: %@:%@", ipAddressString, portString);
					
					[serviceDict setValue: ipAddressString forKey:@"Address"];
					[serviceDict setValue: portString forKey:@"OsiriXPort"];
				}
			}
		}
}

// This object is the delegate of its NSNetServiceBrowser object.
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	// remove my own sharing service
	if( aNetService == [publisher netService] || [[aNetService name] isEqualToString: [NSUserDefaultsController BonjourSharingName]] == YES)
	{
		
	}
	else
	{
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: aNetService, @"service", @"bonjour", @"type", nil];
		
		[services addObject:dict];
		
		// Resolve the address and port for this NSNetService
		
		[aNetService setDelegate:self];
		[aNetService resolveWithTimeout: 5];
	}
	
	// update interface
    if( !moreComing)
	{
		int i = [[BrowserController currentBrowser] currentBonjourService];
	
		NSDictionary	*selectedDict = nil;
		if( i >= 0) 
			selectedDict = [[services objectAtIndex: i] retain];
		
		[self arrangeServices];
		[interfaceOsiriX displayBonjourServices];
		
		if( selectedDict)
		{
			NSInteger index = [services indexOfObject: selectedDict];
			
			if( index == NSNotFound)
				[[BrowserController currentBrowser] resetToLocalDatabase];
			else
				[[BrowserController currentBrowser] setCurrentBonjourService: index];
			
			[selectedDict release];
		}
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)aNetServiceBrowser didRemoveService:(NSNetService*)aNetService moreComing:(BOOL)moreComing 
{
    // This case is slightly more complicated. We need to find the object in the list and remove it.
    NSEnumerator * enumerator = [services objectEnumerator];
    NSNetService * currentNetService;
	
    while( currentNetService = [enumerator nextObject])
	{
        if( [[currentNetService valueForKey: @"service"] isEqual: aNetService])
		{
			NSLog(@"TODO: THIS!!! e-irhesidhieieh if db is alive, kill kill kill it NOW");
			
			if( [interfaceOsiriX currentBonjourService] >= 0)
			{
				if( [services objectAtIndex: [interfaceOsiriX currentBonjourService]] == currentNetService)
					[interfaceOsiriX resetToLocalDatabase];
			}
			
			// deleting service from list
			NSInteger index = [services indexOfObject: currentNetService];
			if( index != NSNotFound)
			{
//				NSLog( @"didRemove retainCout: %d", [currentNetService retainCount]);
				[services removeObjectAtIndex: index];
			}
            break;
        }
    }
	
    if( !moreComing)
	{
		[self arrangeServices];
		[interfaceOsiriX displayBonjourServices];
	}
}



@end
