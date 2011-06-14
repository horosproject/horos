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
#import "basicHTTPServer.h"


/** \brief XML-RPC for RIS integration */
@interface XMLRPCMethods : NSObject
{
	basicHTTPServer	*httpServ;
}

- (void) processXMLRPCMessage: (NSString*) selName httpServerMessage: (NSMutableDictionary*) httpServerMessage HTTPServerRequest: (HTTPServerRequest*) mess version:(NSString*) vers paramDict: (NSDictionary*) paramDict encoding: (NSString*) encoding;
- (void) HTTPConnectionProtected:(basicHTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess;
- (void) postError: (NSInteger) err version: (NSString*) vers message: (HTTPServerRequest *)mess;

@end
