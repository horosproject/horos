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
#import "N2Connection.h"

@interface N2XMLRPCConnection : N2Connection {
	id _delegate;
	BOOL _executed, _waitingToClose;
	NSTimer* _timeout;
}

@property(retain) id delegate;

-(void)handleRequest:(CFHTTPMessageRef)request;
-(void)writeAndReleaseResponse:(CFHTTPMessageRef)response;

@end
