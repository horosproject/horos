/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "XMLRPCMethods.h"
#import "BrowserController.h"

// HTTP SERVER
//
// XML-RPC Standard
//
// XML-RPC Generator for MacOS: http://www.ditchnet.org/xmlrpc/
//
// About XML-RPC: http://www.xmlrpc.com/

@implementation XMLRPCMethods

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		httpServ = [[HTTPServer alloc] init];
		[httpServ setType:@"_http._tcp."];
		[httpServ setName:@"OsiriXXMLRPCServer"];
		[httpServ setPort: [[NSUserDefaults standardUserDefaults] integerForKey:@"httpXMLRPCServerPort"]];
		[httpServ setDelegate:self];
		NSError *error = nil;
		if (![httpServ start:&error]) {
			NSLog(@"Error starting server: %@", error);
		} else {
			NSLog(@"******** Starting HTTP XMLRPC server on port %d", [httpServ port]);
		}
	}
	return self;
}

- (void) dealloc
{
	[httpServ release];
	[super dealloc];
}

#pragma mark-
#pragma mark Methods

- (void)HTTPConnection:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess {
    CFHTTPMessageRef request = [mess request];

    NSString *vers = [(id)CFHTTPMessageCopyVersion(request) autorelease];
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, vers ? (CFStringRef)vers : kCFHTTPVersion1_0); // Version Not Supported
        [mess setResponse:response];
        CFRelease(response);
        return;
    }

    NSString *method = [(id)CFHTTPMessageCopyRequestMethod(request) autorelease];
    if (!method) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
	
    if ([method isEqual:@"POST"])
	{
		int i;
        NSError *error = nil;
        NSData *data = [(id)CFHTTPMessageCopyBody(request) autorelease];
        NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLNodeOptionsNone error:&error] autorelease];
        NSArray *array = [doc nodesForXPath:@"//methodName" error:&error];
		
		if( [array count] == 1)
		{
			NSString *selName = [[array objectAtIndex:0] objectValue];

			NSMutableDictionary	*httpServerMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys: selName, @"MethodName", doc, @"NSXMLDocument", [NSNumber numberWithBool: NO], @"Processed", 0L];
			
			// ********************************************
			// DBWindowFind
			//
			// Method: DBWindowFind
			//
			// Parameters:
			// request: SQL request, see 'Predicate Format String Syntax' from Apple documentation
			// table: OsiriX Table: Image, Series, Study
			// execute: Nothing, Select, Open, Delete
			//
			// Example: {request: "name == 'OsiriX'", table: "Study", execute: "Select"}
			// Example: {request: "(name LIKE '*OSIRIX*')", table: "Study", execute: "Open"}
			//
			// Response: {error: "0"}

			if ([selName isEqual:@"DBWindowFind"])
			{
				NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
				NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
				if (3 != [keys count] || 3 != [values count])
				{
					CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
					[mess setResponse:response];
					CFRelease(response);
					return;
				}
				
				int i;
				NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
				for( i = 0; i < [keys count]; i++)
					[paramDict setValue: [[values objectAtIndex: i] objectValue] forKey: [[keys objectAtIndex: i] objectValue]];	
								
				// *****
				
				NSNumber *ret = [NSNumber numberWithInt: [[BrowserController currentBrowser]	findObject:	[paramDict valueForKey:@"request"]
																								table: [paramDict valueForKey:@"table"]
																								execute: [paramDict valueForKey:@"execute"]]];
				
				// *****
				
				NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
				NSError *error = nil;
				NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
				
				[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];
				[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
			}
			
			// Send the XML-RPC as a notification : give a chance to plugin to answer
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"OsiriXXMLRPCMessage" object: httpServerMessage];
			
			// Did someone processed the message?
			if( [[httpServerMessage valueForKey: @"Processed"] boolValue])
			{
				NSLog( @"XML-RPC Message processed. Sending the reponse.");
				
				NSData *data = [[httpServerMessage valueForKey: @"NSXMLDocumentResponse"] XMLData];
				CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
				CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
				CFHTTPMessageSetBody(response, (CFDataRef)data);
				[mess setResponse:response];
				CFRelease(response);
				return;
			}
			else
			{
				CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_1); // Not found
				[mess setResponse:response];
				CFRelease(response);
				return;
			}
		}
		
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }

    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1); // Method Not Allowed
    [mess setResponse:response];
    CFRelease(response);
}
@end
