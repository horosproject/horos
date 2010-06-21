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

#import <Cocoa/Cocoa.h>
#import "BrowserController.h"

/** \brief  Shares DB with Bonjour */

@interface BonjourPublisher : NSObject
{
	BOOL				dbPublished;
	
//	NSString			*serviceName;
	NSNetService		*netService;
	NSFileHandle		*listeningSocket;

	int					OsiriXDBCurrentPort;
	int					fdForListening;
	int					numberOfConnectedUsers;
	BrowserController	*interfaceOsiriX;
	
	NSLock				*connectionLock, *dicomSendLock;
}

//@property(retain) NSString* serviceName;
@property(retain, readonly) NSNetService* netService;

- (id)initWithBrowserController: (BrowserController*) bC;

- (void)toggleSharing:(BOOL)boo;

// for now, we will only share the name of the shared database
- (void)connectionReceived:(NSNotification *)aNotification;

// work as a delegate of the NSNetService
- (void)netServiceWillPublish:(NSNetService *)sender;
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
- (void)netServiceDidStop:(NSNetService *)sender;

- (NSNetService*) netService;

//- (void)setServiceName:(NSString *) newName;
//- (NSString *) serviceName;
- (int) OsiriXDBCurrentPort;
+ (BonjourPublisher*) currentPublisher;

@end
