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

#import "AppController.h"
#import "XMLRPCMethods.h"
#import "BrowserController.h"
#import "ViewerController.h"
#import "DCMView.h"
#import "QueryController.h"
#import "DCMNetServiceDelegate.h"
#import "Notifications.h"
#import "N2Debug.h"
#import "NSThread+N2.h"
#import "WADODownload.h"
#import "ThreadsManager.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "DCMTKRootQueryNode.h"
#import "NSUserDefaults+OsiriX.h"

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

static NSTimeInterval lastConnection = 0;

@implementation XMLRPCMethods

- (void) separateThread
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSError *error = nil;
    [httpServ start: &error];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while( [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [pool release];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		httpServ = [[basicHTTPServer alloc] init];
		
		[httpServ setType:@"_http._tcp."];

		[httpServ setName:@"OsiriXXMLRPCServer"];
		[httpServ setPort: [[NSUserDefaults standardUserDefaults] integerForKey:@"httpXMLRPCServerPort"]];
		[httpServ setDelegate:self];
		NSError *error = nil;
        
        [NSThread detachNewThreadSelector: @selector( separateThread) toTarget: self withObject: nil];
        
//		if (![httpServ start: &error])
//		{
//			NSLog(@"Error starting HTTP XMLRPC Server: %@", error);
//			NSRunCriticalAlertPanel( NSLocalizedString(@"HTTP XMLRPC Server Error", nil),  [NSString stringWithFormat: NSLocalizedString(@"Error starting HTTP XMLRPC Server: %@", nil), error], NSLocalizedString(@"OK",nil), nil, nil);
//			httpServ = nil;
//		}
//		else
//		{
//			NSLog(@"<><><><><><><> Starting HTTP XMLRPC server on port %d", [httpServ port]);
//		}
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

- (void)HTTPConnection:(basicHTTPConnection *)conn didSendResponse:(HTTPServerRequest *)mess
{

}

- (void) processHTTPConnectionOnMainThread: (NSDictionary*) dict
{
    basicHTTPConnection *conn = [dict objectForKey: @"conn"];
    HTTPServerRequest *mess = [dict objectForKey: @"mess"];
    
    [self HTTPConnectionProtected:conn didReceiveRequest:mess];
}

- (void)HTTPConnection:(basicHTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess
{
	@synchronized( self)
	{
        if( [NSDate timeIntervalSinceReferenceDate] - lastConnection < 0.3)
            [NSThread sleepForTimeInterval: 0.3];
        
        lastConnection = [NSDate timeIntervalSinceReferenceDate];
        
        @try
        {
            [self performSelectorOnMainThread: @selector( processHTTPConnectionOnMainThread:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: conn, @"conn", mess, @"mess", nil] waitUntilDone: YES];
//            [self HTTPConnectionProtected:conn didReceiveRequest:mess];
        }
        
        @catch (NSException * e)
        {
            NSLog( @"HTTPConnection WebServices : %@", e);
        }
    }
}

- (NSDictionary*) getParameters: (NSXMLDocument *) doc encoding: (NSString *) encoding
{
	NSError *error = nil;
	
	NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
	NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
	if( [keys count] != [values count])
		return nil;
	
	int i;
	NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
	for( i = 0; i < [keys count]; i++)
	{
		id value;
		
		if( [encoding isEqualToString:@"UTF-8"] == NO && [[[values objectAtIndex: i] objectValue] isKindOfClass:[NSString class]])
			value = [(NSString*)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)[[values objectAtIndex: i] objectValue], NULL) autorelease];
		else
			value = [[values objectAtIndex: i] objectValue];
		
		NSString *key = [[keys objectAtIndex: i] objectValue];
		
		key = [key stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		[paramDict setValue: value forKey: key];
	}
	
	return paramDict;
}

- (void) showStudy: (NSDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( [dict valueForKey: @"series"])
		[[BrowserController currentBrowser] displayStudy: [dict valueForKey: @"study"] object: [dict valueForKey: @"series"] command: @"Open"];
	else
		[[BrowserController currentBrowser] displayStudy: [dict valueForKey: @"study"] object: [dict valueForKey: @"study"] command: @"Open"];
	
	[pool release];
}

- (void) asyncWADODownload:(NSDictionary*) paramDict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    @try
    {
        NSString *url = [paramDict valueForKey:@"URL"];
        
        WADODownload *downloader = [[WADODownload alloc] init];
        
        [downloader WADODownload: [NSArray arrayWithObject: [NSURL URLWithString: url]]];
        
        [downloader release];
        
        if( [[paramDict valueForKey:@"Display"] boolValue])
        {
            NSString *studyUID = nil;
            NSString *seriesUID = nil;
            
            for( NSString *s in [[[url componentsSeparatedByString: @"?"] lastObject] componentsSeparatedByString: @"&"])
            {
                NSRange separatorRange = [s rangeOfString: @"="];
                
                if( separatorRange.location != NSNotFound)
                {
                    @try
                    {
                        if( [[s substringToIndex: separatorRange.location] isEqualToString: @"studyUID"])
                            studyUID = [s substringFromIndex: separatorRange.location+1];
                            
                        if( [[s substringToIndex: separatorRange.location] isEqualToString: @"seriesUID"])
                            seriesUID = [s substringFromIndex: separatorRange.location+1];
                    }
                    @catch (NSException * e) { NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
                }
                else NSLog( @"**** no studyUID");
            }
            
            if( studyUID)
            {
                BOOL found = NO;
                NSTimeInterval started = [NSDate timeIntervalSinceReferenceDate];
                
                NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
                [dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"Study"]];
                
                if( studyUID && seriesUID)
                    [dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@ AND ANY series.seriesDICOMUID == %@", studyUID, seriesUID]];
                else
                    [dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
                
                DicomStudy *study = nil;
                DicomSeries *series = nil;
                
                while( found == NO && [NSDate timeIntervalSinceReferenceDate] - started < 300)
                {
                    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
                    
                    NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
                    
                    [context lock];
                    
                    @try
                    {
                        NSError *error = nil;
                        NSArray *array = [context executeFetchRequest:dbRequest error:&error];
                        
                        if( [[[array lastObject] valueForKey:@"studyInstanceUID"] isEqualToString: studyUID])
                        {
                            study = [array lastObject];
                            
                            if( seriesUID)
                            {
                                for( DicomSeries *s in [study.series allObjects])
                                {
                                    if( [s.seriesDICOMUID isEqualToString: seriesUID])
                                        series = s;
                                }
                            }
                            found = YES;
                        }
                    }
                    @catch (NSException * e) { NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
                    
                    [context unlock];
                }
                
                if( found)
                    [self performSelectorOnMainThread: @selector( showStudy:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: study, @"study", series, @"series", nil] waitUntilDone: NO];
            }
        }   
    }
    @catch (NSException * e) { NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
    
	[pool release];
}

- (void) retrieve:(NSDictionary*) dict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    for( DCMTKQueryNode	*study in [dict valueForKey: @"children"])
    {
        [study move: dict retrieveMode: [[dict valueForKey: @"retrieveMode"] intValue]];
    }
    
    [pool release];
}

- (void) processXMLRPCMessage: (NSString*) selName httpServerMessage: (NSMutableDictionary*) httpServerMessage HTTPServerRequest: (HTTPServerRequest*) mess version:(NSString*) vers paramDict: (NSDictionary*) paramDict encoding: (NSString*) encoding
{
	if( vers == nil)
		vers = [NSString stringWithString: (NSString*) kCFHTTPVersion1_1];
	
	selName = [selName lowercaseString];
	
#pragma mark KillOsiriX			
	if ( [selName isEqualToString:@"killosirix"])
		[[AppController sharedAppController] performSelector:@selector(terminate:) withObject:self afterDelay:0];

#pragma mark DownloadURL
	// ********************************************
	// Method: DownloadURL
	//
	// Parameters:
	// URL: any URLs that return a file compatible with OsiriX, including .dcm, .zip, .osirixzip, ...
	// Display: display the images at the end of the download? (Optional parameter : it requires a WADO URL, containing the studyUID parameter)
	//
	// Example: {URL: "http://127.0.0.1:3333/wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX"}
	// Response: {error: "0"}
	
	if ([selName isEqualToString:@"downloadurl"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if( [paramDict count] < 1)
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			//DLog(@"\tParamDict: %@", paramDict);
			
			NSString *listOfElements = nil;
			NSNumber *ret = nil;
			
			@try
			{
				if( [[paramDict valueForKey:@"URL"] length])
				{
					NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( asyncWADODownload:) object: paramDict] autorelease];
					t.name = NSLocalizedString( @"WADO Retrieve...", nil);
					t.supportsCancel = YES;
					t.status = [paramDict valueForKey:@"URL"];
					[[ThreadsManager defaultManager] addThreadAndStart: t];
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"****** XML-RPC Exception: %@", e);
			}
			
			// *****
			NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
			[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
			[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
	}
	
	
#pragma mark DisplayStudy
	
	// ********************************************
	// Method: DisplayStudy / DisplaySeries
	//
	// Parameters:
	// PatientID:  0010,0020
	// StudyID:  0020,0010 (DisplayStudy)
	// or
	// SeriesInstanceUID: 0020,000e (DisplaySeries)
	//
	// Example: {PatientID: "1100697", StudyID: "A10043712203"}
	// Example: {PatientID: "1100697", SeriesInstanceUID: "1.3.12.2.1107.5.1.4.54693.30000007120706534864000001110"}
	// Response: {error: "0", elements: array of elements corresponding to the request}
	
	if ([selName isEqualToString:@"displaystudy"] || [selName isEqualToString:@"displayseries"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (2 != [paramDict count] && 1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			//DLog(@"\tParamDict: %@", paramDict);
			
			NSString *listOfElements = nil;
			NSNumber *ret = nil;
			
			@try
			{
				if ([selName isEqualToString:@"displaystudy"])
				{
					if( [[paramDict valueForKey:@"PatientID"] length] > 0 && [[paramDict valueForKey:@"StudyInstanceUID"] length] > 0)
						ret = [NSNumber numberWithInt: [[BrowserController currentBrowser] findObject:[NSString stringWithFormat: @"patientID =='%@' AND studyInstanceUID == '%@'", [paramDict valueForKey:@"PatientID"], [paramDict valueForKey:@"StudyInstanceUID"]] table: @"Study" execute: @"Open" elements: &listOfElements]];
					else if( [[paramDict valueForKey:@"PatientID"] length] > 0)
						ret = [NSNumber numberWithInt: [[BrowserController currentBrowser] findObject:[NSString stringWithFormat: @"patientID == '%@'", [paramDict valueForKey:@"PatientID"]] table: @"Study" execute: @"Open" elements: &listOfElements]];
					else if( [[paramDict valueForKey:@"StudyInstanceUID"] length] > 0)
						ret = [NSNumber numberWithInt: [[BrowserController currentBrowser] findObject:[NSString stringWithFormat: @"studyInstanceUID == '%@'", [paramDict valueForKey:@"StudyInstanceUID"]] table: @"Study" execute: @"Open" elements: &listOfElements]];
				}
				
				if ([selName isEqualToString:@"displayseries"])
				{
					if( [[paramDict valueForKey:@"PatientID"] length] > 0 && [[paramDict valueForKey:@"SeriesInstanceUID"] length] > 0)
						ret = [NSNumber numberWithInt: [[BrowserController currentBrowser]	findObject:	[NSString stringWithFormat: @"study.patientID =='%@' AND seriesDICOMUID == '%@'", [paramDict valueForKey:@"PatientID"], [paramDict valueForKey:@"SeriesInstanceUID"]] table: @"Series" execute: @"Open" elements: &listOfElements]];
					else if( [[paramDict valueForKey:@"SeriesInstanceUID"] length] > 0)
						ret = [NSNumber numberWithInt: [[BrowserController currentBrowser]	findObject:	[NSString stringWithFormat: @"seriesDICOMUID == '%@'", [paramDict valueForKey:@"SeriesInstanceUID"]] table: @"Series" execute: @"Open" elements: &listOfElements]];
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"****** XML-RPC Exception: %@", e);
			}
			
			// *****
			NSString *xml;
			if( listOfElements)
				xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member><member><name>elements</name>%@</member></struct></value></param></params></methodResponse>", [ret stringValue], listOfElements];
			else
				xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
			[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
			[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
	}
	
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
	
	if ([selName isEqualToString:@"dbwindowfind"] || [selName isEqualToString:@"findobject"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (3 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			
			NSString *listOfElements = nil;
			
			NSNumber *ret = [NSNumber numberWithInt: [[BrowserController currentBrowser]	findObject:	[paramDict valueForKey:@"request"]
																							  table: [paramDict valueForKey:@"table"]
																							execute: [paramDict valueForKey:@"execute"]
																						   elements: &listOfElements]];
			
			// *****
			
			// Use  <?xml version=\"1.0\" encoding=\"UTF-8\"?>  ??? 
			
			NSString *xml;
			if( listOfElements)
				xml = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member><member><name>elements</name>%@</member></struct></value></param></params></methodResponse>", [ret stringValue], listOfElements];
			else
				xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
			[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
			[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
	}
	
#pragma mark SwitchToDefaultDBIfNeeded
	
	// ********************************************
	// Method: SwitchToDefaultDBIfNeeded
	//
	// Parameters:
	// No parameter
	//
	// Response: {error: "0"}
	
	if ([selName isEqualToString:@"switchtodefaultdbifneeded"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			NSNumber *ret = [NSNumber numberWithInt: 0];
			
			[[BrowserController currentBrowser] switchToDefaultDBIfNeeded];
			
			// Done, we can send the response to the sender
			
			NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
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
	
	if ([selName isEqualToString:@"opendb"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			
			NSNumber *ret = [NSNumber numberWithInt: 0];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: [paramDict valueForKey:@"path"]])
				[[BrowserController currentBrowser] openDatabasePath: [paramDict valueForKey:@"path"]];
			else ret = [NSNumber numberWithInt: -1];
			
			// *****
			NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
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
	
	if ([selName isEqualToString:@"selectalbum"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			
			NSTableView	*albumTable = [[BrowserController currentBrowser] albumTable];
			NSArray	*albumArray = [[BrowserController currentBrowser] albumArray];
			NSNumber *ret = [NSNumber numberWithInt: -1];
			
			for( NSManagedObject *album in albumArray)
			{
				if( [[album valueForKey:@"name"] isEqualToString: [paramDict valueForKey:@"name"]])
				{
					[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [albumArray indexOfObject: album]] byExtendingSelection: NO];
					ret = [NSNumber numberWithInt: 0];
				}
			}
			
			// *****
			NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
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
	
	if( [selName isEqualToString: @"closeallwindows"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			for( ViewerController *v in [ViewerController getDisplayed2DViewers])
				[[v window] close];
			
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
	
	if( [selName isEqualToString: @"getdisplayed2dviewerseries"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			
			// Generate an answer containing the elements
			NSMutableString *a = [NSMutableString stringWithString: @"<value><array><data>"];
			
			for( id loopItem5 in viewersList)
			{
				NSMutableString *c = [NSMutableString stringWithString: @"<value><struct>"];
				
				NSManagedObject *series = [[loopItem5 imageView] seriesObj];
				
				NSArray *allKeys = [[[[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"Series"] attributesByName] allKeys];
				
				for (NSString *keyname in allKeys)
				{
					@try
					{
						if( [[series valueForKey: keyname] isKindOfClass:[NSString class]] ||
						   [[series valueForKey: keyname] isKindOfClass:[NSDate class]] ||
						   [[series valueForKey: keyname] isKindOfClass:[NSNumber class]])
						{
							NSString *value = [[series valueForKey: keyname] description];
							value = [(NSString*)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)value, NULL) autorelease];
							[c appendFormat: @"<member><name>%@</name><value>%@</value></member>", keyname, value];
						}
					}
					
					@catch (NSException * e)
					{
					}
				}
				
				[c appendString: @"</struct></value>"];
				
				[a appendString: c];
			}
			[a appendString: @"</data></array></value>"];
			
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
	
	if( [selName isEqualToString: @"getdisplayed2dviewerstudies"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			
			// Generate an answer containing the elements
			NSMutableString *a = [NSMutableString stringWithString: @"<value><array><data>"];
			
			for( id loopItem4 in viewersList)
			{
				NSMutableString *c = [NSMutableString stringWithString: @"<value><struct>"];
				
				NSManagedObject *study = [[[loopItem4 imageView] seriesObj] valueForKey:@"study"];
				
				NSArray *allKeys = [[[[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"Study"] attributesByName] allKeys];
				
				for (NSString *keyname in allKeys)
				{
					@try
					{
						if( [[study valueForKey: keyname] isKindOfClass:[NSString class]] ||
						   [[study valueForKey: keyname] isKindOfClass:[NSDate class]] ||
						   [[study valueForKey: keyname] isKindOfClass:[NSNumber class]])
						{
							NSString *value = [[study valueForKey: keyname] description];
							value = [(NSString*)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)value, NULL) autorelease];
							[c appendFormat: @"<member><name>%@</name><value>%@</value></member>", keyname, value];
						}
					}
					
					@catch (NSException * e)
					{
					}
				}
				
				[c appendString: @"</struct></value>"];
				
				[a appendString: c];
			}
			[a appendString: @"</data></array></value>"];
			
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
	
	if( [selName isEqualToString: @"close2dviewerwithseriesuid"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			
			// *****
			
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			
			for( int i = 0; i < [viewersList count] ; i++)
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
	
	if( [selName isEqualToString: @"close2dviewerwithstudyuid"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			
			// *****
			
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			
			for( int i = 0; i < [viewersList count] ; i++)
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

#pragma mark Retrieve
    // ********************************************
	// Method: Retrieve
	//
	// Parameters:
    //
	// serverName: 
	// filterValue: 
    // filterKey:
	//
	// Example: osirix://?methodName=retrieve&serverName=Minipacs&filterKey=PatientID&filterValue=296228
	//
	// Response: {error: "0"}
	
	if( [selName isEqualToString: @"retrieve"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (3 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
            
            NSNumber *ret = [NSNumber numberWithInt: -1];
            
			// *****
            @try
            {
                NSArray *sources = [DCMNetServiceDelegate DICOMServersList];
                NSDictionary *sourceServer = nil;
                
                
                for( NSDictionary *s in sources)
                {
                    if( [[s valueForKey:@"Description"] isEqualToString: [paramDict valueForKey:@"serverName"]]) // We found the source server
                    {
                        sourceServer = s;
                        break;
                    }
                }
                
                if( sourceServer)
                {
                    //We found the DICOM node, prepare the query
                    DCMTKRootQueryNode *rootNode = [[DCMTKRootQueryNode alloc] initWithDataset: nil
                                                                                    callingAET: [NSUserDefaults defaultAETitle]
                                                                                     calledAET: [sourceServer objectForKey:@"AETitle"]
                                                                                      hostname: [sourceServer objectForKey:@"Address"]
                                                                                          port: [[sourceServer objectForKey:@"Port"] intValue]
                                                                                transferSyntax: 0
                                                                                   compression: nil
                                                                               extraParameters: sourceServer];
                    
                    NSArray *filterArray = [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: [paramDict objectForKey: @"filterValue"], @"value", [paramDict objectForKey: @"filterKey"], @"name", nil]];
                    
                    if( [paramDict objectForKey: @"filterValue2"] && [paramDict objectForKey: @"filterKey2"])
                    {
                        filterArray = [filterArray arrayByAddingObject:
                                       [NSDictionary dictionaryWithObjectsAndKeys: [paramDict objectForKey: @"filterValue2"], @"value", [paramDict objectForKey: @"filterKey2"], @"name", nil]];
                    }
                    
                    if( [paramDict objectForKey: @"filterValue3"] && [paramDict objectForKey: @"filterKey3"])
                    {
                        filterArray = [filterArray arrayByAddingObject:
                                       [NSDictionary dictionaryWithObjectsAndKeys: [paramDict objectForKey: @"filterValue3"], @"value", [paramDict objectForKey: @"filterKey3"], @"name", nil]];
                    }
                    
                    [rootNode queryWithValues: filterArray];
                    
                    int retrieveMode = CMOVERetrieveMode;
                    if( [[sourceServer valueForKey: @"retrieveMode"] intValue] == WADORetrieveMode)
                        retrieveMode = WADORetrieveMode;
                    if( [[sourceServer valueForKey: @"retrieveMode"] intValue] == CGETRetrieveMode)
                        retrieveMode = CGETRetrieveMode;
                    
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSUserDefaults defaultAETitle], @"moveDestination", [NSNumber numberWithInt: retrieveMode] , @"retrieveMode", [rootNode children], @"children", nil];
                    
                    if( [[rootNode children] count])
                    {
                        ret = [NSNumber numberWithInt: 0];
                        [NSThread detachNewThreadSelector: @selector( retrieve:) toTarget: self withObject: dict];
                    }
                    else
                    {
                        NSLog( @"--- study not found");
                        ret = [NSNumber numberWithInt: -3];
                    }
                }
                else
                {
                    NSLog( @"--- server not found");
                    ret = [NSNumber numberWithInt: -2];
                }
            }
            @catch (NSException * e) { NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
            
            // Done, we can send the response to the sender
			
			NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
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
	
	if( [selName isEqualToString: @"cmove"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (2 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			
			NSArray *sources = [DCMNetServiceDelegate DICOMServersList];
			NSDictionary *sourceServer = nil;
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
				[[[BrowserController currentBrowser] managedObjectContext] unlock];	// CMove requires this unlock !
				
				@try
				{
					ret = [NSNumber numberWithInt :[QueryController queryAndRetrieveAccessionNumber: [paramDict valueForKey:@"accessionNumber"] server: sourceServer]];
				}
				@catch (NSException * e)
				{
					NSLog( @"***** queryAndRetrieveAccessionNumber exception: %@", e);
				}
				
				[[[BrowserController currentBrowser] managedObjectContext] lock];
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
	
#pragma mark DisplayStudyListByPatientName
	
	// ********************************************
	// Method: DisplayStudyListByPatientName
	//
	// Parameters:
	// PatientName: name of the patient
	//
	// Example: {PatientName: "DOE^JOHN"}
	//
	// Response: {error: "0"}
	
	if ([selName isEqualToString:@"displaystudylistbypatientname"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			
			NSNumber *ret = [NSNumber numberWithInt: 0];
			
			[[BrowserController currentBrowser] setSearchString:[paramDict valueForKey:@"PatientName"]];
			
			// *****
			NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
			[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
			[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
	}
	
#pragma mark DisplayStudyListByPatientId
	
	// ********************************************
	// Method: DisplayStudyListByPatientId
	//
	// Parameters:
	// PatientID: patient ID
	//
	// Example: {id: "0123456789"}
	//
	// Response: {error: "0"}
	
	if ([selName isEqualToString:@"displaystudylistbypatientid"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			if (1 != [paramDict count])
			{
				[self postError: 400 version: vers message: mess];
				return;
			}
			// *****
			
			NSNumber *ret = [NSNumber numberWithInt: 0];
			
			[[BrowserController currentBrowser] setSearchString:[paramDict valueForKey:@"PatientID"]];
			
			// *****
			NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%@</value></member></struct></value></param></params></methodResponse>", [ret stringValue]];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
			[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
			[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
	}
    
    if ([selName isEqualToString:@"pathtofrontdcm"])
	{
		if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)							// Is this order already processed ?
		{
			[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];
			ViewerController *frontViewer = [ViewerController frontMostDisplayed2DViewer];
			NSString	*path = @"";
			if (frontViewer){ // is there a front viewer?
				path  = [[BrowserController currentBrowser] getLocalDCMPath:[[frontViewer fileList] objectAtIndex:[[frontViewer imageView] curImage]] :0];
				if (paramDict && [[paramDict valueForKey:@"onlyfilename"] isEqualToString:@"yes"]) path = [path lastPathComponent];
			}
			// We must build an AppleScript response 'cause Applescript doesn't understand XMLRPC responses. The response is a dictionary.
			id ASResponse;
			ASResponse = [NSDictionary dictionaryWithObject:path forKey:@"currentDCMPath"];
			[httpServerMessage setValue:ASResponse forKey: @"ASResponse"];
			
			NSString *xmlrpcresponse = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>currentDCMPath</name><value>%@</value></member></struct></value></param></params></methodResponse>", path];
			
			NSError *error = nil;
			NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString: xmlrpcresponse options:NSXMLNodeOptionsNone error:&error] autorelease];
			[httpServerMessage setValue:doc forKey:@"NSXMLDocumentResponse"];
            [httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
	}
}

- (void) postError: (NSInteger) err version: (NSString*) vers message: (HTTPServerRequest *)mess 
{
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, err, NULL, (CFStringRef) vers); // Bad Request
	NSString *xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%d</value></member></struct></value></param></params></methodResponse>", err];
	NSLog( @"***** xml error returned: %@", xml);
	NSError *error = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
	NSData *data = [doc XMLData];
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
	CFHTTPMessageSetBody(response, (CFDataRef)data);
	[mess setResponse:response];
	CFRelease(response);
}

- (void)HTTPConnectionProtected:(basicHTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess
{
    CFHTTPMessageRef request = [mess request];
	
	// curl -d @/Users/antoinerosset/Desktop/test.xml "http://localhost:8080"
	
//	NSDictionary *allHeaderFields = [(id)CFHTTPMessageCopyAllHeaderFields(request) autorelease];
//	NSLog( @"%@", allHeaderFields);
	
    NSString *vers = [(id)CFHTTPMessageCopyVersion(request) autorelease];
    if (!vers)
	{
        [self postError: 505 version: vers message: mess];
		
        return;
    }

    NSString *method = [(id)CFHTTPMessageCopyRequestMethod(request) autorelease];
    if (!method)
	{
        [self postError: 400 version: vers message: mess];
		
        return;
    }
	
    if ([method isEqual:@"POST"])
	{
        NSError *error = nil;
        NSData *data = [(id)CFHTTPMessageCopyBody(request) autorelease];
        NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLNodeOptionsNone error:&error] autorelease];
		
		if( error)
			NSLog( @"***** %@", error);
		
		NSString *encoding = [doc characterEncoding];
		
        NSArray *array = [doc nodesForXPath:@"//methodName" error:&error];
		
		if( [array count] == 1)
		{
			NSString *selName = [[array objectAtIndex:0] objectValue];
			DLog(@"XMLRPC call: %@", selName);
			
			selName = [selName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			char buffer[256];
			NSString *ipAddressString = @"";
			
			struct sockaddr *addr = (struct sockaddr *) [[conn peerAddress] bytes];
			if( addr->sa_family == AF_INET)
			{
				if (inet_ntop(AF_INET, &((struct sockaddr_in *)addr)->sin_addr, buffer, sizeof(buffer)))
					ipAddressString = [NSString stringWithCString:buffer];
			}
			
			NSMutableDictionary	*httpServerMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys: selName, @"MethodName", doc, @"NSXMLDocument", [NSNumber numberWithBool: NO], @"Processed", ipAddressString, @"peerAddress", nil];
			
			#pragma mark-
			#pragma mark Send the XML-RPC as a notification
			
			// Send the XML-RPC as a notification : give a chance to plugin to answer
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixXMLRPCMessageNotification object: httpServerMessage];
			
			// Did someone processed the message?
			if( [[httpServerMessage valueForKey: @"Processed"] boolValue])
			{
				//NSLog( @"XML-RPC Message processed. Sending the reponse.");
				
				NSData *data = [[httpServerMessage valueForKey: @"NSXMLDocumentResponse"] XMLData];
				CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, (CFStringRef) vers); // OK
				CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
				CFHTTPMessageSetBody(response, (CFDataRef)data);
				[mess setResponse:response];
				CFRelease(response);
				
				return;
			}
			else // Built-in messages
			{
				NSDictionary *paramDict = [self getParameters: doc encoding: encoding];
				
				[self processXMLRPCMessage: selName httpServerMessage: httpServerMessage HTTPServerRequest: mess version: vers paramDict: paramDict encoding: encoding];
			}
			
			if( [[httpServerMessage valueForKey: @"Processed"] boolValue] == NO)
			{
				[self postError: 404 version: vers message: mess];
				
				NSLog( @"**** unable to understand this xml-rpc message: %@", selName);
				NSLog( @"%@", doc);
				NSLog( @"************************************************************");
				
				return;
			}
			else
			{
				NSData *data = [[httpServerMessage valueForKey: @"NSXMLDocumentResponse"] XMLData];
				CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, (CFStringRef) vers); // OK
				CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
				CFHTTPMessageSetBody(response, (CFDataRef)data);
				[mess setResponse:response];
				CFRelease(response);
				
				return;
			}
		}
		NSLog( @"**** Bad Request : methodName?");
		[self postError: 400 version: vers message: mess];
		
        return;
    }

	NSLog( @"**** Bad Request: we accept only http POST");

   [self postError: 405 version: vers message: mess];
}
@end
