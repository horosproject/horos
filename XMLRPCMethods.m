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
#import "ViewerController.h"
#import "DCMView.h"
#import "QueryController.h"
#import "DCMNetServiceDelegate.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

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
		if (![httpServ start:&error])
		{
			NSLog(@"Error starting HTTP XMLRPC Server: %@", error);
			NSRunCriticalAlertPanel( NSLocalizedString(@"HTTP XMLRPC Server Error", 0L),  [NSString stringWithFormat: NSLocalizedString(@"Error starting HTTP XMLRPC Server: %@", 0L), error], NSLocalizedString(@"OK",nil), nil, nil);
			httpServ = 0L;
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
		
		NSLog( [doc description]);
		
        NSArray *array = [doc nodesForXPath:@"//methodName" error:&error];
		
		if( [array count] == 1)
		{
			NSString *selName = [[array objectAtIndex:0] objectValue];
			char buffer[256];
			NSString *ipAddressString = @"";
			
			struct sockaddr *addr = (struct sockaddr *) [[conn peerAddress] bytes];
			if( addr->sa_family == AF_INET)
			{
				if (inet_ntop(AF_INET, &((struct sockaddr_in *)addr)->sin_addr, buffer, sizeof(buffer)))
					ipAddressString = [NSString stringWithCString:buffer];
			}
			
			NSMutableDictionary	*httpServerMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys: selName, @"MethodName", doc, @"NSXMLDocument", [NSNumber numberWithBool: NO], @"Processed", ipAddressString, @"peerAddress", 0L];
			
			#pragma mark DBWindowFind
			
			// ********************************************
			// Method: DBWindowFind
			//
			// Parameters:
			// request: SQL request, see 'Predicate Format String Syntax' from Apple documentation
			// table: OsiriX Table: Image, Series, Study
			// execute: Nothing, Select, Open, Delete
			//
			// execute is performed at the  study level: you cannot delete a single series of a study
			//
			// Example: {request: "name == 'OsiriX'", table: "Study", execute: "Select"}
			// Example: {request: "(name LIKE '*OSIRIX*')", table: "Study", execute: "Open"}
			//
			// Response: {error: "0", elements: array of elements corresponding to the request}
			
			if ([selName isEqual:@"DBWindowFind"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
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
					
					NSString *listOfElements = 0L;
					
					NSNumber *ret = [NSNumber numberWithInt: [[BrowserController currentBrowser]	findObject:	[paramDict valueForKey:@"request"]
																									table: [paramDict valueForKey:@"table"]
																									execute: [paramDict valueForKey:@"execute"]
																									elements: &listOfElements]];
					
					// *****
					NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member><member><name>elements</name>%@</member></struct></value></param></params></methodResponse>", [ret stringValue], listOfElements];
					
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark OpenDB
			
			// ********************************************
			// Method: OpenDB
			//
			// Parameters:
			// path: path of the folder containing the 'OsiriX Data' folder
			//
			// if path is valid, but not DB is found, OsiriX will create a new one
			//
			// Example: {path: "/Users/antoinerosset/Documents/"}
			//
			// Response: {error: "0"}
			
			if ([selName isEqual:@"OpenDB"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
					NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
					if (1 != [keys count] || 1 != [values count])
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
					
					NSNumber *ret = [NSNumber numberWithInt: 0];
					
					if( [[NSFileManager defaultManager] fileExistsAtPath: [paramDict valueForKey:@"path"]])
						[[BrowserController currentBrowser] openDatabasePath: [paramDict valueForKey:@"path"]];
					else ret = [NSNumber numberWithInt: -1];
					
					// *****
					NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
					
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark SelectAlbum
			
			// ********************************************
			// Method: SelectAlbum
			//
			// Parameters:
			// name: name of the album
			//
			// Example: {name: "Today"}
			//
			// Response: {error: "0"}
			
			if ([selName isEqual:@"SelectAlbum"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
					NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
					if (1 != [keys count] || 1 != [values count])
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
					
					NSTableView	*albumTable = [[BrowserController currentBrowser] albumTable];
					NSArray	*albumArray = [[BrowserController currentBrowser] albumArray];
					NSNumber *ret = [NSNumber numberWithInt: -1];
					
					for( NSManagedObject *album in albumArray)
					{
						if( [[album valueForKey:@"name"] isEqualToString: [paramDict valueForKey:@"name"]])
						{
							[albumTable selectRow: [albumArray indexOfObject: album] byExtendingSelection: NO];
							ret = [NSNumber numberWithInt: 0];
						}
					}
					
					// *****
					NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
					
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark CloseAllWindows
			
			// ********************************************
			// Method: CloseAllWindows
			//
			// Parameters: No Parameters
			//
			// Response: {error: "0"}

			if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"CloseAllWindows"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
					
					for( id loopItem6 in viewersList)
					{
						[[loopItem6 window] close];
					}
					
					// Done, we can send the response to the sender
					
					NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark GetDisplayed2DViewerSeries
			
			// ********************************************
			// Method: GetDisplayed2DViewerSeries
			//
			// Parameters: No Parameters
			//
			// Response: {error: "0", elements: array of series corresponding to displayed windows}

			if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"GetDisplayed2DViewerSeries"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
					
					// Generate an answer containing the elements
					NSMutableString *a = [NSMutableString stringWithString: @"<array><data>"];
					
					for( id loopItem5 in viewersList)
					{
						NSMutableString *c = [NSMutableString stringWithString: @"<struct>"];
						
						NSManagedObject *series = [[loopItem5 imageView] seriesObj];
						
						NSDictionary *allCommittedValues = [series committedValuesForKeys:nil];
			
						for (NSString *keyname in [allCommittedValues allKeys])
						{
							@try
							{
								if( [[allCommittedValues valueForKey: keyname] isKindOfClass:[NSString class]] ||
									[[allCommittedValues valueForKey: keyname] isKindOfClass:[NSDate class]] ||
									[[allCommittedValues valueForKey: keyname] isKindOfClass:[NSNumber class]])
								[c appendFormat: @"<member><name>%@</name><value>%@</value></member>", keyname, [[allCommittedValues valueForKey: keyname] description]];
							}
							
							@catch (NSException * e)
							{
							}
						}
						
						[c appendString: @"</struct>"];
						
						[a appendString: c];
					}
					[a appendString: @"</data></array>"];
					
					// Done, we can send the response to the sender
					NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member><member><name>elements</name>%@</member></struct></value></param></params></methodResponse>", @"0", a];
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}

			#pragma mark GetDisplayed2DViewerStudies

			// ********************************************
			// Method: GetDisplayed2DViewerStudies
			//
			// Parameters: No Parameters
			//
			// Response: {error: "0", elements: array of studies corresponding to displayed windows}

			if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"GetDisplayed2DViewerStudies"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
					
					// Generate an answer containing the elements
					NSMutableString *a = [NSMutableString stringWithString: @"<array><data>"];
					
					for( id loopItem4 in viewersList)
					{
						NSMutableString *c = [NSMutableString stringWithString: @"<struct>"];
						
						NSManagedObject *study = [[[loopItem4 imageView] seriesObj] valueForKey:@"study"];
						
						NSDictionary *allCommittedValues = [study committedValuesForKeys:nil];
			
						for (NSString *keyname in [allCommittedValues allKeys])
						{
							@try
							{
								if( [[allCommittedValues valueForKey: keyname] isKindOfClass:[NSString class]] ||
									[[allCommittedValues valueForKey: keyname] isKindOfClass:[NSDate class]] ||
									[[allCommittedValues valueForKey: keyname] isKindOfClass:[NSNumber class]])
								[c appendFormat: @"<member><name>%@</name><value>%@</value></member>", keyname, [[allCommittedValues valueForKey: keyname] description]];
							}
							
							@catch (NSException * e)
							{
							}
						}
						
						[c appendString: @"</struct>"];
						
						[a appendString: c];
					}
					[a appendString: @"</data></array>"];
					
					// Done, we can send the response to the sender
					NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member><member><name>elements</name>%@</member></struct></value></param></params></methodResponse>", @"0", a];
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark Close2DViewerWithSeriesUID
			
			// ********************************************
			// Method: Close2DViewerWithSeriesUID
			//
			// Parameters:
			// uid: series instance uid to close
			//
			// Example: {uid: "1.3.12.2.1107.5.1.4.51988.4.0.1164229612882469"}
			//
			// Response: {error: "0"}
			
			if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"Close2DViewerWithSeriesUID"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
					NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
					if (1 != [keys count] || 1 != [values count])
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
					
					NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
					
					for( i = 0; i < [viewersList count] ; i++)
					{
						NSManagedObject *series = [[[viewersList objectAtIndex: i] imageView] seriesObj];
						
						if( [[series valueForKey:@"seriesDICOMUID"] isEqualToString: [paramDict valueForKey:@"uid"]])
							[[[viewersList objectAtIndex: i] window] close];
					}
					
					// Done, we can send the response to the sender
					
					NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark Close2DViewerWithStudyUID
			
			// ********************************************
			// Method: Close2DViewerWithStudyUID
			//
			// Parameters:
			// uid: study instance uid to close
			//
			// Example: {uid: "1.2.840.113745.101000.1008000.37915.4331.5559218"}
			//
			// Response: {error: "0"}
			
			if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"Close2DViewerWithStudyUID"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
					NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
					if (1 != [keys count] || 1 != [values count])
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
					
					NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
					
					for( i = 0; i < [viewersList count] ; i++)
					{
						NSManagedObject *study = [[[[viewersList objectAtIndex: i] imageView] seriesObj] valueForKey:@"study"];
						
						if( [[study valueForKey:@"studyInstanceUID"] isEqualToString: [paramDict valueForKey:@"uid"]])
							[[[viewersList objectAtIndex: i] window] close];
					}
					
					// Done, we can send the response to the sender
					
					NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark CMove
			
			// ********************************************
			// Method: CMove
			//
			// Parameters:
			// accessionNumber: accessionNumber of the study to retrieve
			// server: server description where the images are located (See OsiriX Locations Preferences)
			//
			// Example: {accessionNumber: "UA876410", server: "Main-PACS"}
			//
			// Response: {error: "0"}
			
			if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"CMove"])
			{
				if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
				{
					NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
					NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
					if (2 != [keys count] || 2 != [values count])
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
					
					NSArray *sources = [DCMNetServiceDelegate DICOMServersList];
					NSDictionary *sourceServer = 0L;
					NSNumber *ret = [NSNumber numberWithInt: 0];
					
					for( NSDictionary *s in sources)
					{
						if( [[s valueForKey:@"Description"] isEqualToString: [paramDict valueForKey:@"server"]]) // We found the source server
						{
							sourceServer = s;
							
							break;
						}
					}
					
					if( sourceServer)
					{
						ret = [NSNumber numberWithInt :[QueryController queryAndRetrieveAccessionNumber: [paramDict valueForKey:@"accessionNumber"] server: sourceServer]];
					}
					else ret = [NSNumber numberWithInt: -1];
					
					// Done, we can send the response to the sender
					
					NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
					NSError *error = nil;
					NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
					[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
					[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
				}
			}
			
			#pragma mark-
			#pragma mark Send the XML-RPC as a notification
			
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
