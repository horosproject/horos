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

#import "SOAPMethods.h"
#import "BrowserController.h"

@implementation SOAPMethods

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		httpServ = [[HTTPServer alloc] init];
		[httpServ setType:@"_http._tcp."];
		[httpServ setName:@"OsiriXSOAPServer"];
		[httpServ setPort: [[NSUserDefaults standardUserDefaults] integerForKey:@"httpSOAPServerPort"]];
		[httpServ setDelegate:self];
		NSError *error = nil;
		if (![httpServ start:&error]) {
			NSLog(@"Error starting server: %@", error);
		} else {
			NSLog(@"Starting server on port %d", [httpServ port]);
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
#pragma mark SOAP Methods

- (NSNumber *)add:(NSNumber *)num1 to:(NSNumber *)num2 {
    return [NSNumber numberWithDouble:[num1 doubleValue] + [num2 doubleValue]];
}

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

#if 0
    // useful for testing with Safari
    if ([method isEqual:@"GET"]) {
        [[conn server] setDocumentRoot:[NSURL fileURLWithPath:@"/"]];
        [conn performDefaultRequestHandling:mess];
        return;
    }
#endif

    if ([method isEqual:@"POST"])
	{
        NSError *error = nil;
        NSData *data = [(id)CFHTTPMessageCopyBody(request) autorelease];
        NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLNodeOptionsNone error:&error] autorelease];
        NSArray *array = [doc nodesForXPath:@"soap:Envelope/soap:Body/ex:MethodName" error:&error];
        NSString *selName = [[array objectAtIndex:0] objectValue];
		
		// ********************************************
		// TEST SOAP FUNCTION ADD
		
        if ([selName isEqual:@"add:to:"])
		{
            NSArray *array = [doc nodesForXPath:@"soap:Envelope/soap:Body/ex:Parameters/ex:Parameter" error:&error];
            if (2 != [array count]) {
                CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
                [mess setResponse:response];
                CFRelease(response);
                return;
            }
            
            NSXMLNode *node1 = [array objectAtIndex:0];
            NSNumber *num1 = [NSNumber numberWithDouble:[[node1 objectValue] doubleValue]];
            NSXMLNode *node2 = [array objectAtIndex:1];
            NSNumber *num2 = [NSNumber numberWithDouble:[[node2 objectValue] doubleValue]];
            NSNumber *ret = [self add:num1 to:num2];
            NSString *xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?> <soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:ex=\"http://www.osirix-viewer.com\"> <soap:Body> <ex:Result>%@</ex:Result> </soap:Body> </soap:Envelope>", ret];
            NSError *error = nil;
            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
            NSData *data = [doc XMLData];
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
            CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
            CFHTTPMessageSetBody(response, (CFDataRef)data);
            [mess setResponse:response];
            CFRelease(response);
            return;
        }
		
		// 
		// Use SOAP Client to test your messages: http://scan.dalo.us/
		//
		
		// ********************************************
		// DBWindowFind
		//
		//	<?xml version="1.0"?>
		//	<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ex="http://localhost:8080">
		//	<soap:Body>
		//	<ex:MethodName>DBWindowFind</ex:MethodName>
		//	<ex:Parameters> <ex:Object>object</ex:Object>				See Table fields
		//	<ex:Key>key</ex:Key> <ex:Table>table</ex:Table>				Study, Series, Image
		//	<ex:Execute>Nothing</ex:Execute> </ex:Parameters>			Nothing, Select, Open
		//	</soap:Body>
		//	</soap:Envelope>

		else if ([selName isEqual:@"DBWindowFind:"])
		{
            NSArray *array = [doc nodesForXPath:@"soap:Envelope/soap:Body/ex:Parameters/ex:Parameter" error:&error];
            if (4 != [array count]) {
                CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
                [mess setResponse:response];
                CFRelease(response);
                return;
            }
            
            NSString *object = [[array objectAtIndex:0] objectValue];
			NSString *key = [[array objectAtIndex:1] objectValue];
			NSString *table = [[array objectAtIndex:2] objectValue];
			NSString *execute = [[array objectAtIndex:3] objectValue];		// Nothing, Select, Open
			
			// *****
			
			NSNumber *ret = [NSNumber numberWithInt: [[BrowserController currentBrowser] findObject: object key: key table: table execute: execute]];
			
			// *****
			
			NSString *xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?> <soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:ex=\"http://www.osirix-viewer.com\"> <soap:Body> <ex:Result>%@</ex:Result> </soap:Body> </soap:Envelope>", ret];
            NSError *error = nil;
            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
            NSData *data = [doc XMLData];
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
            CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
            CFHTTPMessageSetBody(response, (CFDataRef)data);
            [mess setResponse:response];
            CFRelease(response);
            return;
        }
        else
		{
			NSLog( @"SOAP MethodName not found. Send it as a Notification. A plugin will maybe execute it.");
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
