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

#import <Cocoa/Cocoa.h>
#import "BrowserController.h"

@interface BonjourPublisher : NSObject
{
	NSString			*serviceName;
	NSNetService		*netService;
	NSFileHandle		*listeningSocket;

	int					fdForListening;
	int					numberOfConnectedUsers;
	BrowserController	*interfaceOsiriX;
}

- (id)initWithBrowserController: (BrowserController*) bC;

- (void)toggleSharing:(BOOL)boo;

// for now, we will only share the name of the shared database
- (void)connectionReceived:(NSNotification *)aNotification;

// work as a delegate of the NSNetService
- (void)netServiceWillPublish:(NSNetService *)sender;
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
- (void)netServiceDidStop:(NSNetService *)sender;

- (NSNetService*) netService;

- (void)setServiceName:(NSString *) newName;
- (NSString *) serviceName;

@end
