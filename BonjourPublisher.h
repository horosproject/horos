/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
