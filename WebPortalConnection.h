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
#import "HTTPConnection.h"
#import "WebPortalUser.h"

@class WebPortal, WebPortalServer, WebPortalSession, WebPortalResponse;

@interface WebPortalConnection : HTTPConnection
{
	NSLock *sendLock, *running;
	WebPortalUser* user;
	WebPortalSession* session;
	
	NSString* requestedPath;
	NSString* GETParams;
	NSDictionary* parameters; // GET and POST params
	
	WebPortalResponse* response;
	
	// POST / PUT support
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;
	NSData *postBoundary;
	NSString *POSTfilename;

}

-(CFHTTPMessageRef)request;

@property(retain,readonly) WebPortalResponse* response;
@property(retain,readonly) WebPortalSession* session;
@property(retain,readonly) WebPortalUser* user;
@property(retain,readonly) NSDictionary* parameters;
@property(retain,readonly) NSString* GETParams;

@property(assign,readonly) WebPortalServer* server;
@property(assign,readonly) WebPortal* portal;
@property(assign,readonly) AsyncSocket* asyncSocket;

+(NSString*)FormatParams:(NSDictionary*)dict;
+(NSDictionary*)ExtractParams:(NSString*)paramsString;

-(BOOL)requestIsIPhone;
-(BOOL)requestIsIPad;
-(BOOL)requestIsIPod;
-(BOOL)requestIsIOS;
-(BOOL)requestIsMacOS;

-(NSString*)portalAddress;
-(NSString*)portalURL;
-(NSString*)dicomCStorePortString;

- (void) fillSessionAndUserVariables;

@end
