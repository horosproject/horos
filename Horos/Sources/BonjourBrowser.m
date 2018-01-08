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
#import "N2Debug.h"

@implementation BonjourBrowser

static BonjourBrowser *currentBrowser = nil;

+(BonjourBrowser*)currentBrowser {
    return currentBrowser;
}

-(id)initWithBrowserController:(BrowserController*)bC {
    if ((self = [super init])) {
        
        currentBrowser = self;
        
        browser = [[NSNetServiceBrowser alloc] init];
        services = [[NSMutableArray array] retain];
        
        [self buildFixedIPList];
        [self buildLocalPathsList];
        [self buildDICOMDestinationsList];
        //		[[BrowserController currentBrowser] loadDICOMFromiPod];
        [self arrangeServices];
        
        interfaceOsiriX = bC;
        
        //[browser setDelegate:self];
        
        //if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"] == NO)
        //	[browser searchForServicesOfType:@"_osirixdb._tcp." inDomain:@""];
        
        //		[browser scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"SERVERS" options:NSKeyValueObservingOptionInitial context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(updateFixedList:)
                                                     name: @"DCMNetServicesDidChange"
                                                   object: nil];
    }
    
    return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
        if( [keyPath isEqualToString: @"values.SERVERS"])
        {
            [self updateFixedList: nil];
        }
    }
}

- (void) dealloc
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"SERVERS"];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
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
    NSString	*defaultPath = [DicomDatabase baseDirPathForMode:[[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] path:[[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
    
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
        
        if( [[dict valueForKey:@"Path"] isEqualToString: defaultPath] == NO &&
           [[[dict valueForKey:@"Path"] stringByAppendingPathComponent:@"Horos Data"] isEqualToString: defaultPath] == NO)
        {
            [dict setValue:@"localPath" forKey:@"type"];
            [services addObject: dict];
        }
    }
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) updateFixedList: (NSNotification*) note
{
    [self buildFixedIPList];
    [self buildLocalPathsList];
    //[[BrowserController currentBrowser] loadDICOMFromiPod];
    [self buildDICOMDestinationsList];
    [self arrangeServices];
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


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [sender stop];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
    [sender retain];
    @try
    {
        if ([[sender addresses] count] > 0)
        {
            NSData * address;
            struct sockaddr * socketAddress = nil;
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
            
            if (socketAddress)
            {
                switch(socketAddress->sa_family)
                {
                    case AF_INET:
                        if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer)))
                        {
                            ipAddressString = [NSString stringWithUTF8String:buffer];
                            portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
                        }
                        break;
                    case AF_INET6:
                        if (inet_ntop(AF_INET6, &((struct sockaddr_in6 *)socketAddress)->sin6_addr, buffer, sizeof(buffer)))
                        {
                            ipAddressString = [NSString stringWithUTF8String:buffer];
                            portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in6 *)socketAddress)->sin6_port)];
                        }
                        break;
                }
            }
            
            if( ipAddressString && portString)
            {
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
        
        [sender stop];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    @finally {
        [sender release];
    }
}

@end
