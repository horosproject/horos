//
//  NetworkListener.m
//  OsiriX
//
//  Created by Lance Pysher on 2/16/05.

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


#import "NetworkListener.h"
//#import "NetworkDataHandler.h"
#import "OsiriXSCPDataHandler.h"


@implementation NetworkListener

+ (id)listenWithParameters:(NSDictionary *)params{
	NetworkListener *listener = [[[NetworkListener alloc] initWithParameters:params] autorelease];
	[NSThread detachNewThreadSelector:@selector(listen:) toTarget:listener withObject:nil]; 
	return listener;	
}


- (void)newConnection:(NSFileHandle *)socketHandle{
	NSAutoreleasePool *pool = nil;
	NS_DURING 
		[socketHandle retain];
		[socketListener acceptConnectionInBackgroundAndNotify];	
		
		pool = [[NSAutoreleasePool alloc] init];
		NSLog(@"new connection thread: %@", [[NSThread currentThread] description]);
		NSArray *objects = [NSArray arrayWithObjects:socketHandle, folder, calledAET,[OsiriXSCPDataHandler requestDataHandlerWithDestinationFolder:folder  debugLevel:0], [NSNumber numberWithInt:120000],  [NSNumber numberWithInt:0], nil];
		NSArray *keys= [NSArray arrayWithObjects:@"socketHandle", @"folder", @"calledAET", @"receivedDataHandler", @"timeout", @"debugLevel",  nil];
		NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[DCMStoreSCP runStoreSCP:params];

	NS_HANDLER
		 NSLog(@"Exception raised: %@", [localException name]);
	NS_ENDHANDLER
	NSLog(@"exit listener thread%@", [[NSThread currentThread] description]);
	if (pool)
		[pool release];
	if (socketHandle)
		[socketHandle release];	
	
	
}

@end
