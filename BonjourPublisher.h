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

@class N2ConnectionListener;

@interface BonjourPublisher : NSObject <NSNetServiceDelegate>
{
    N2ConnectionListener* _listener;
	
    NSNetService* _bonjour;
    
	NSLock* dicomSendLock;
}

//@property(retain) NSString* serviceName;
//@property(retain, readonly) NSNetService* netService;

- (void)toggleSharing:(BOOL)activate;

// for now, we will only share the name of the shared database
//- (void)connectionReceived:(NSNotification *)aNotification;

// work as a delegate of the NSNetService
//- (void)netServiceWillPublish:(NSNetService *)sender;
//- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
//- (void)netServiceDidStop:(NSNetService *)sender;

- (NSNetService*)netService __deprecated;

//- (void)setServiceName:(NSString *) newName;
//- (NSString *) serviceName;
- (int) OsiriXDBCurrentPort __deprecated; // use -[[[AppController sharedAppController] bonjourPublisher] port]
+ (BonjourPublisher*) currentPublisher __deprecated; // use -[[AppController sharedAppController] bonjourPublisher]

+ (NSDictionary*)dictionaryFromXTRecordData:(NSData*)data;

@end
