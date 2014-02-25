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

#import "WebPortalConnection.h"
#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "WebPortalDatabase.h"
#import "WebPortalSession.h"
#import "WebPortalResponse.h"
#import "WebPortalConnection+Data.h"
#import "WebPortalUser.h"
#import "WebPortalStudy.h"
#import "DicomDatabase.h"
#import "AsyncSocket.h"
#import "DDKeychain.h"
#import "BrowserController.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "DicomImage.h"
#import "DCMTKStoreSCU.h"
#import "DCMPix.h"
#import "DCMNetServiceDelegate.h"
#import "AppController.h"
#import "BrowserControllerDCMTKCategory.h"
#import "DCM.h"
#import "HTTPResponse.h"
#import "HTTPAuthenticationRequest.h"
#import "CSMailMailClient.h"
#import "DicomFile.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "N2Debug.h"
#import "NSString+N2.h"
#import "NSUserDefaultsController+N2.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "NSString+N2.h"
#import "DDData.h"
#import "NSData+N2.h"
#import "NSMutableString+N2.h"
#import "NSImage+N2.h"
#import "NSMutableDictionary+N2.h"
#import "DicomAlbum.h"
#import "N2Alignment.h"
#import "AppController.h"
#import "PluginManager.h"

#import "JSON.h"

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// TODO: NSUserDefaults access for keys @"logWebServer", @"notificationsEmailsSender" and @"lastNotificationsDate" must be replaced with WebPortal properties

static NSMutableArray *pluginWithHTTPResponses = nil;

//static NSString* NotNil(NSString *s) {
//	return s? s : @"";
//}

@interface HTTPConnection (Private) // make compiler aware of these hidden methods' existance

-(BOOL)isAuthenticated;
-(void)replyToHTTPRequest;
-(BOOL)onSocketWillConnect:(AsyncSocket*)sock;

@end

@interface WebPortalConnection ()

@property(retain,readwrite) WebPortalResponse* response;

@end

@implementation WebPortalConnection

@synthesize response;
@synthesize session;
@synthesize user;
@synthesize parameters, GETParams;

-(WebPortalSession*)session {
	if (!session)
		self.session = [self.portal newSession];
	[self.response setSessionId:session.sid];
	return session;
}

-(BOOL)requestIsIPhone {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"iPhone"];
}

-(BOOL)requestIsIPad {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"iPad"];	
}

-(BOOL)requestIsIPod {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"iPod"];	
}

-(BOOL)requestIsIOS {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"like Mac OS X"];	
}

-(BOOL)requestIsMacOS {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"Mac OS X"];	
}

-(id)initWithAsyncSocket:(AsyncSocket*)newSocket forServer:(HTTPServer*)myServer {
	self = [super initWithAsyncSocket:newSocket forServer:myServer];
	sendLock = [[NSLock alloc] init];
    
	return self;
}

- (void) managedObjectContextDidSaveNotification: (NSNotification*) n
{
    NSManagedObjectContext *moc = n.object;
    
    if (_independentDicomDatabase.managedObjectContext == moc)
        return;
    
    if ( _independentDicomDatabase.managedObjectContext.persistentStoreCoordinator != moc.persistentStoreCoordinator)
        return;
    
    @try {
        [_independentDicomDatabase.managedObjectContext performSelector: @selector( mergeChangesFromContextDidSaveNotification:) onThread: _independentDicomDatabaseThread withObject: n waitUntilDone: NO];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
}

-(DicomDatabase*)independentDicomDatabase
{
    if( [NSThread isMainThread])
        return self.portal.dicomDatabase;
    
    if (_independentDicomDatabase)
    {
        if( [NSThread currentThread] != _independentDicomDatabaseThread)
            N2LogStackTrace( @"***************** [NSThread currentThread] != _independentDicomDatabaseThread");
        
        return _independentDicomDatabase;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSManagedObjectContextDidSaveNotification object: nil];
    
    _independentDicomDatabase = [[self.portal.dicomDatabase independentDatabase] retain];
    
    [_independentDicomDatabaseThread release];
    _independentDicomDatabaseThread = [[NSThread currentThread] retain];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector( managedObjectContextDidSaveNotification:) name: NSManagedObjectContextDidSaveNotification object: nil];
    
    return _independentDicomDatabase;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[sendLock lock];
	[sendLock unlock];
	[sendLock release];
	
	self.user = nil;
	
	[multipartData release];
	[postBoundary release];
	[POSTfilename release];
	
    self.response = nil;
    self.GETParams = nil;
    self.parameters = nil;
	self.session = nil;
    
    if ([_independentDicomDatabase.managedObjectContext hasChanges])
        [_independentDicomDatabase save];
    [_independentDicomDatabase release];
	[_independentDicomDatabaseThread release];
    
	[super dealloc];
}

-(WebPortal*)portal {
	return self.server.portal;
}

-(WebPortalServer*)server {
	return (WebPortalServer*)server;
}

-(AsyncSocket*)asyncSocket {
	return asyncSocket;
}

-(CFHTTPMessageRef)request {
	return request;
}

-(NSString*)portalURL
{
    NSString* requestedHost = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Host") autorelease];
	if (!self.portal.usesSSL && [requestedHost hasSuffix:@":80"]) requestedHost = [requestedHost substringWithRange:NSMakeRange(0,requestedHost.length-3)];
	if (self.portal.usesSSL && [requestedHost hasSuffix:@":443"]) requestedHost = [requestedHost substringWithRange:NSMakeRange(0,requestedHost.length-4)];
    
    if( requestedHost == nil)
        return self.portal.URL;
    else
    {
        return [NSString stringWithFormat:@"%@://%@", self.portal.usesSSL? @"https" : @"http", requestedHost];
    }
}

NSString* const SessionDicomCStorePortKey = @"DicomCStorePort"; // NSNumber (int)

-(int)guessDicomCStorePort
{
	DLog(@"Trying to guess DICOM C-Store Port...");
	
	for (NSDictionary *node in [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO])
	{
//		NSString *dicomNodeAddress = NotNil([node objectForKey:@"Address"]);
		int dicomNodePort = [[node objectForKey:@"Port"] intValue];
		
		struct sockaddr_in service;
		const char	*host_name = [[node valueForKey:@"Address"] UTF8String];
		
		bzero((char *) &service, sizeof(service));
		service.sin_family = AF_INET;
		
		if (host_name)
		{
			if (isalpha(host_name[0]))
			{
				struct hostent* hp = gethostbyname(host_name);
				if (hp) bcopy(hp->h_addr, (char*)&service.sin_addr, hp->h_length);
				else service.sin_addr.s_addr = inet_addr(host_name);
			}
			else service.sin_addr.s_addr = inet_addr(host_name);
			
			char buffer[256];
			if (inet_ntop(AF_INET, &service.sin_addr, buffer, sizeof(buffer)))
			{
				if ([[NSString stringWithCString:buffer] isEqualToString:[asyncSocket connectedHost]]) // TODO: this may fail because of comparaisons between ipv6 and ipv4 addys
				{
					DLog( @"\tFound! %@:%d", [asyncSocket connectedHost], dicomNodePort);
					return dicomNodePort;
				}
			}
		}
	}
	
	DLog(@"\tNot found, will use 11112");
	return 11112;
}

-(NSString*)dicomCStorePortString {
	NSNumber* n = [self.session objectForKey:SessionDicomCStorePortKey];
	if (!n) [self.session setObject: n = [NSNumber numberWithInt:[self guessDicomCStorePort]] forKey:SessionDicomCStorePortKey];
	return [n stringValue];
}

-(BOOL)isPasswordProtected:(NSString*)path
{
	if ([path hasPrefix: @"/wado"]
	|| [path hasPrefix: @"/images/"]
	|| [path isEqualToString: @"/"]
	|| [path hasSuffix: @".js"]
	|| [path hasSuffix: @".css"]
	|| [path hasPrefix: @"/password_forgotten"]
	|| [path hasPrefix: @"/index"]
	|| [path hasPrefix:@"/weasis/"]
	|| [path isEqualToString: @"/favicon.ico"]
    || [path isEqualToString: @"/testdbalive"])
		return NO;
    
    for (id key in [PluginManager plugins])
    {
        id plugin = [[PluginManager plugins] objectForKey:key];
        
        if ([plugin respondsToSelector:@selector(isPasswordProtected:forConnection:)])
        {
            NSNumber *v = [plugin performSelector: @selector(isPasswordProtected:forConnection:) withObject: path withObject: self];
            
            if( v)
                return [v boolValue];
        }
    }
    
	return self.portal.authenticationRequired;
}

-(BOOL)useDigestAccessAuthentication {
	return NO;
}

// Overrides HTTPConnection's method
- (BOOL)isSecureServer {
	return self.portal.usesSSL;
}

/**
 * Overrides HTTPConnection's method
 * 
 * This method is expected to return an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 **/
- (NSArray *)sslIdentityAndCertificates
{
//	NSArray *result = [DDKeychain SSLIdentityAndCertificates];
	id identity = (id)[DDKeychain KeychainAccessPreferredIdentityForName:@"com.osirixviewer.osirixwebserver" keyUse:CSSM_KEYUSE_ANY];
	if (identity == nil)
	{
		[DDKeychain createNewIdentity];
		identity = (id)[DDKeychain KeychainAccessPreferredIdentityForName:@"com.osirixviewer.osirixwebserver" keyUse:CSSM_KEYUSE_ANY];
	}
	
	NSMutableArray *array = [NSMutableArray arrayWithObject:identity];
	
	// We add the chain of certificates that validates the chosen certificate.
	// This way we don't have to install the intermediate certificates on the clients systems. Yay!
	NSArray *certificateChain = [DDKeychain KeychainAccessCertificateChainForIdentity:(SecIdentityRef)identity];
	[array addObjectsFromArray:certificateChain];

	return [NSArray arrayWithArray:array];
}

/*
- (NSRect) centerRect: (NSRect) smallRect
               inRect: (NSRect) bigRect
{
    NSRect centerRect;
    centerRect.size = smallRect.size;

    centerRect.origin.x = (bigRect.size.width - smallRect.size.width) / 2.0;
    centerRect.origin.y = (bigRect.size.height - smallRect.size.height) / 2.0;

    return (centerRect);
}*/
/*
+(NSString*)ipv6:(NSString*)inadd {
	const char* inaddc = [[node valueForKey:@"Address"] UTF8String];
	
	struct sockaddr_in service;
	bzero((char*)&service, sizeof(service));
	
	service.sin_family = AF_INET6;
	
}*/

+(NSString*)FormatParams:(NSDictionary*)dict {
	NSMutableString* str = [NSMutableString string];
	for (NSString* key in dict) {
		NSString* value = [dict objectForKey:key];
		if ([value isKindOfClass: [NSArray class]])
			for (NSString* v2 in (NSArray*)value)
				[str appendFormat:@"%@%@=%@", str.length?@"&":@"", [key urlEncodedString], [v2 urlEncodedString]];
		else [str appendFormat:@"%@%@=%@", str.length?@"&":@"", [key urlEncodedString], [value urlEncodedString]];
	} return str;
}

+(NSDictionary*)ExtractParams:(NSString*)paramsString {
	if (!paramsString.length)
		return [NSDictionary dictionary];
	
	NSArray* paramsArray = [paramsString componentsSeparatedByString:@"&"];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:paramsArray.count];

	for (NSString* param in paramsArray)
	{
		NSArray* paramArray = [param componentsSeparatedByString:@"="];
		
		NSString* paramName = [[[paramArray objectAtIndex:0] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (!paramName.length)
			continue;
		
		NSString* paramValue = paramArray.count > 1? [[[paramArray objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : (NSString*)[NSNull null];
		
		NSMutableArray* prevVal = [params objectForKey:paramName];
		if (prevVal && ![prevVal isKindOfClass:[NSMutableArray class]]) {
			prevVal = [NSMutableArray arrayWithObject:prevVal];
			[params setObject:prevVal forKey:paramName];
		}
		
		if (prevVal)
			[prevVal addObject:paramValue];
		else [params setObject:paramValue forKey:paramName];
	}
	
	return params;
}

- (void) alive:(id) sender
{
    [self.portal.dicomDatabase.managedObjectContext lock]; // Can we obtain a lock on the main db?
    [self.portal.dicomDatabase.managedObjectContext unlock];
}

- (NSObject<HTTPResponse>*)httpResponseForMethod:(NSString*)method URI:(NSString*)path
{
	NSString* url = [[(id)CFHTTPMessageCopyRequestURL(request) autorelease] relativeString];
	
	// parse the URL to find the parameters (if any)
	NSArray *urlComponenents = [url componentsSeparatedByString:@"?"];
    
	if ([urlComponenents count] == 2) self.GETParams = [urlComponenents lastObject];
	else self.GETParams = nil;
	
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	// GET params
	[params addEntriesFromDictionary:[WebPortalConnection ExtractParams: self.GETParams]];
	// POST params
	if ([method isEqualToString: @"POST"] && multipartData.count == 1) {
		NSString* POSTParams = [[[NSString alloc] initWithBytes: [[multipartData lastObject] bytes] length: [(NSData*) [multipartData lastObject] length] encoding: NSUTF8StringEncoding] autorelease];
		[params addEntriesFromDictionary:[WebPortalConnection ExtractParams:POSTParams]];
	}
	self.parameters = params;
	[response.tokens setObject:parameters forKey:@"Request"];
	
	// find the name of the requested file
	// SECURITY: we cannot allow the client to read any file on the hard disk (outside the shared dir), so no ".." 
	requestedPath = [[urlComponenents objectAtIndex:0] stringByReplacingOccurrencesOfString:@"../" withString:@""];
	
//	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
//	BOOL isIOS [userAgent contains:@"iPhone"] || [userAgent contains:@"iPad"];	
//	BOOL isMacOS [userAgent contains:@"Mac OS"];	

	NSString* ext = [requestedPath pathExtension];
	if ([ext compare:@"jar" options:NSCaseInsensitiveSearch|NSLiteralSearch] == NSOrderedSame)
		response.mimeType = @"application/java-archive";
	if ([ext compare:@"swf" options:NSCaseInsensitiveSearch|NSLiteralSearch] == NSOrderedSame)
		response.mimeType = @"application/x-shockwave-flash";
    if( [ext compare:@"css" options:NSCaseInsensitiveSearch|NSLiteralSearch] == NSOrderedSame)
        response.mimeType = @"text/css";
    if( [ext compare:@"js" options:NSCaseInsensitiveSearch|NSLiteralSearch] == NSOrderedSame)
        response.mimeType = @"application/javascript";
	
//    [response.httpHeaders setObject: @"no-cache" forKey: @"Cache-Control"];
    
	if ([requestedPath hasPrefix:@"/weasis/"])
	{
		#ifndef OSIRIX_LIGHT
		response.data = [NSData dataWithContentsOfFile:[[[AppController sharedAppController] weasisBasePath] stringByAppendingPathComponent:requestedPath]];
		#else
		response.statusCode = 404;
		#endif
	}
	else if ([requestedPath rangeOfString:@".pvt."].length)
    {
		response.statusCode = 404;
	}
	else
	{
        BOOL handledByPlugin = NO;
        @try
        {
            // Maybe a plugin has an answer ?
            if( pluginWithHTTPResponses == nil)
            {
                pluginWithHTTPResponses = [[NSMutableArray alloc] init];
                for( id key in [PluginManager plugins])
                {
                    id plugin = [[PluginManager plugins] objectForKey:key];
                    
                    if( [plugin respondsToSelector:@selector(httpResponseForPath:forConnection:)])
                        [pluginWithHTTPResponses addObject: plugin];
                }
            }
            
            for( id plugin in pluginWithHTTPResponses)
            {
                NSData *data = [plugin performSelector: @selector(httpResponseForPath:forConnection:) withObject: requestedPath withObject: self];
                
                if( data.length)
                {
                    response.data = data;
                    handledByPlugin = YES;
                    break;
                }
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        
        if( handledByPlugin == NO)
        {
            @try
            {
                if ([requestedPath isEqualToString:@"/"] || [requestedPath hasPrefix: @"/index"])
                    [self processIndexHtml];
                else
                if ([requestedPath isEqualToString: @"/main"])
                    [self processMainHtml];
                else
                if ([requestedPath isEqualToString:@"/logs"])
                    [self processLogsListHtml];
                else
                if ([requestedPath isEqualToString:@"/studyList"])
                    [self processStudyListHtml];
                else	
                if ([requestedPath isEqualToString:@"/studyList.json"])
                    [self processStudyListJson];
                else
                if ([requestedPath isEqualToString:@"/study"])
                    [self processStudyHtml];
                else
                if ([requestedPath isEqualToString:@"/wado"])
                    [self processWado];
                else
                if ([requestedPath isEqualToString:@"/thumbnail"])
                    [self processThumbnail];
                else
                if ([requestedPath isEqualToString:@"/series.pdf"])
                    [self processSeriesPdf];
                else
                if ([requestedPath isEqualToString:@"/series"])
                    [self processSeriesHtml];
                else
                if ([requestedPath isEqualToString:@"/keyroisimages"])
                    [self processKeyROIsImagesHtml];
                else
                if ([requestedPath isEqualToString:@"/series.json"])
                    [self processSeriesJson];
                else
                if ([requestedPath hasPrefix:@"/report"])
                    [self processReport];
                else
                if ([requestedPath hasSuffix:@".zip"] || [requestedPath hasSuffix:@".osirixzip"])
                    [self processZip];
                else
                if ([requestedPath hasPrefix:@"/image."])
                    [self processImage];
                else
                if ([requestedPath hasPrefix:@"/imageAsScreenCapture."])
                    [self processImageAsScreenCapture: YES];
                else
                if ([requestedPath isEqualToString:@"/movie.mov"] || [requestedPath isEqualToString:@"/movie.m4v"] || [requestedPath isEqualToString:@"/movie.mp4"] || [requestedPath isEqualToString:@"/movie.swf"])
                    [self processMovie];
                else
                if ([requestedPath isEqualToString:@"/password_forgotten"])
                    [self processPasswordForgottenHtml];
                else
                if ([requestedPath isEqualToString: @"/account"])
                    [self processAccountHtml];
                else
                if ([requestedPath isEqualToString:@"/albums.json"])
                    [self processAlbumsJson];
                else
                if ([requestedPath isEqualToString:@"/seriesList.json"])
                    [self processSeriesListJson];
                else
                if ([requestedPath hasSuffix:@"weasis.jnlp"])
                    [self processWeasisJnlp];
                else
                if ([requestedPath isEqualToString:@"/weasis.xml"])
                    [self processWeasisXml];
                else
                if ([requestedPath isEqualToString:@"/admin/"] || [requestedPath isEqualToString:@"/admin/index"])
                    [self processAdminIndexHtml];
                else
                if ([requestedPath isEqualToString:@"/admin/user"])
                    [self processAdminUserHtml];
                else
                if ([requestedPath isEqualToString:@"/quitOsiriX"] && user.isAdmin.boolValue)
                    exit(0);
                else if ([requestedPath isEqualToString:@"/testdbalive"])
                {
                    [self.portal.dicomDatabase.managedObjectContext lock]; // Can we obtain a lock on the main db?
                    [self.portal.dicomDatabase.managedObjectContext unlock];
                    
                    [self.portal.dicomDatabase.managedObjectContext.persistentStoreCoordinator lock]; // Can we obtain a lock on the main db?
                    [self.portal.dicomDatabase.managedObjectContext.persistentStoreCoordinator unlock];
                    
                    [self.portal.database.managedObjectContext lock];
                    [self.portal.database objectsForEntity:self.portal.database.userEntity predicate:[NSPredicate predicateWithFormat:@"name == %@", @"test"]];
                    [self.portal.database.managedObjectContext unlock];
                    
                    [self.portal.database.managedObjectContext.persistentStoreCoordinator lock];
                    [self.portal.database.managedObjectContext.persistentStoreCoordinator unlock];
                    
                    [self performSelectorOnMainThread: @selector( alive:) withObject: self waitUntilDone: YES];
                    
                    [response setDataWithString: @"Test DB Alive succeeded"];
                    response.mimeType = @"text/html";
                }
                else
                {
                    response.data = [self.portal dataForPath:requestedPath];
                }
                
                if (!response.data.length && !response.statusCode)
                    response.statusCode = 404;
            }
            @catch (NSException* e)
            {
                response.statusCode = 500;
                NSLog(@"Error: [WebPortalConnection httpResponseForMethod:URI:] %@", e);
            }
        }
	}
	
	if (response.data && !response.statusCode)
		return [[response retain] autorelease]; // [[[WebPortalResponse alloc] initWithData:data mime:dataMime sessionId:session.sid] autorelease];*/
	else return NULL;
}

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath {
	if ([method isEqualToString:@"POST"])
		return YES;
	return [super supportsMethod:method atPath:relativePath];
}

- (void) resetPOST
{
	dataStartIndex = 0;
	[multipartData release];
	multipartData = [[NSMutableArray alloc] init];
	postHeaderOK = FALSE;
	
	[postBoundary release];
	postBoundary = nil;
	
	[POSTfilename release];
	POSTfilename = nil;
	
	return;
}

- (BOOL) checkEOF:(NSData*) postDataChunk range: (NSRange*) r
{
//	BOOL eof = NO;
	int l = [postBoundary length];
	
	const NSUInteger CHECKLASTPART = 4096;
	
	for ( int x = [postDataChunk length]-CHECKLASTPART; x < [postDataChunk length]-l; x++)
	{
		if (x >= 0)
		{
			NSRange searchRange = {static_cast<NSUInteger>(x), static_cast<NSUInteger>(l)};
			
			// If MacOS 10.6 : we should use - (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
			
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData: postBoundary])
			{
				r->length -= ([postDataChunk length] - x) +2; // -2 = 0x0A0D
				return YES;
			}
		}
	}
	return NO;
}

- (void) closeFileHandleAndClean
{
	NSString *file;
//	NSString *root = [[BrowserController currentBrowser] INCOMINGPATH];
	NSMutableArray *filesArray = [NSMutableArray array];
	
	if ([[POSTfilename pathExtension] isEqualToString: @"zip"] || [[POSTfilename pathExtension] isEqualToString: @"osirixzip"])
	{
		NSTask *t = [[[NSTask alloc] init] autorelease];
		
		[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/osirixUnzippedFolder" error: nil];
		
		@try
		{
			[t setLaunchPath: @"/usr/bin/unzip"];
			[t setCurrentDirectoryPath: @"/tmp/"];
			NSArray *args = [NSArray arrayWithObjects: @"-o", @"-d", @"osirixUnzippedFolder", POSTfilename, nil];
			[t setArguments: args];
			[t launch];
			while( [t isRunning])
                [NSThread sleepForTimeInterval: 0.1];
            
            //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
		}
		@catch( NSException *e)
		{
			NSLog( @"***** unzipFile exception: %@", e);
		}
		
		if (POSTfilename)
			[[NSFileManager defaultManager] removeItemAtPath: POSTfilename error: nil];
		
		NSString *rootDir = @"/tmp/osirixUnzippedFolder";
		BOOL isDirectory = NO;
		
		for ( NSString *file in [[NSFileManager defaultManager] subpathsOfDirectoryAtPath: rootDir error: nil])
		{
			if ([file hasSuffix: @".DS_Store"] == NO && [[file lastPathComponent] isEqualToString: @"DICOMDIR"] == NO && [[file lastPathComponent] hasPrefix: @"__MACOSX"] == NO && [[NSFileManager defaultManager] fileExistsAtPath: [rootDir stringByAppendingPathComponent: file] isDirectory: &isDirectory] && isDirectory == NO)
				[filesArray addObject: [rootDir stringByAppendingPathComponent: file]];
		}
	}
	else
		[filesArray addObject: POSTfilename];
	
	NSString *previousPatientUID = nil;
	NSString *previousStudyInstanceUID = nil;
	
	[self fillSessionAndUserVariables];
	
    DicomDatabase *idatabase = self.independentDicomDatabase;
	NSMutableArray *filesAccumulator = [NSMutableArray array];
	// We want to find this file after db insert: get studyInstanceUID, patientUID and instanceSOPUID
	for ( NSString *oFile in filesArray)
	{
		DicomFile *f = [[[DicomFile alloc] init: oFile DICOMOnly: YES] autorelease];
		
		if( f)
		{
			file = [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"];
				
			[[NSFileManager defaultManager] moveItemAtPath: oFile toPath: file error: nil];
			
			[filesAccumulator addObject: file];
			
			NSString *studyInstanceUID = [f elementForKey: @"studyID"], *patientUID = [f elementForKey: @"patientUID"];
				
			if ([studyInstanceUID isEqualToString: previousStudyInstanceUID] == NO || [patientUID compare: previousPatientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
			{
                [idatabase addFilesAtPaths: filesAccumulator postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:YES importedFiles:YES returnArray:NO];
				
				[filesAccumulator removeAllObjects];
				
				previousStudyInstanceUID = [[studyInstanceUID copy] autorelease];
				previousPatientUID = [[patientUID copy] autorelease];
				
				if (studyInstanceUID && patientUID)
				{
					@try
					{
						NSFetchRequest *dbRequest = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
						[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@) AND (studyInstanceUID == %@)", patientUID, studyInstanceUID]];
						
						NSError *error = nil;
						NSArray *studies = [idatabase.managedObjectContext executeFetchRequest: dbRequest error:&error];
						
						if ([studies count] == 0)
							NSLog( @"****** [studies count == 0] cannot find the file{s} we just received... upload POST: %@ %@", patientUID, studyInstanceUID);
						
						// Add study to specific study list for this user
						if (user.uploadDICOMAddToSpecificStudies.boolValue)
						{
							NSArray *studies = [idatabase objectsForEntity:idatabase.studyEntity predicate:[NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@) AND (studyInstanceUID == %@)", patientUID, studyInstanceUID]];
							
							if ([studies count] == 0)
								NSLog( @"****** [studies count == 0] cannot find the file{s} we just received... upload POST: %@ %@", patientUID, studyInstanceUID);
							
							// Add study to specific study list for this user
							
							NSArray *studiesArrayStudyInstanceUID = [user.studies.allObjects valueForKey:@"studyInstanceUID"];
							NSArray *studiesArrayPatientUID = [user.studies.allObjects valueForKey: @"patientUID"];
							
							for( NSManagedObject *study in studies)
							{
								if ([[study valueForKey: @"type"] isEqualToString:@"Series"])
									study = [study valueForKey:@"study"];
								
                                if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || 
                                   [studiesArrayPatientUID indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { if( [obj compare: [study valueForKey: @"patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame) return YES; else return NO;}] == NSNotFound)
								{
									NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext: user.managedObjectContext];
									
									[studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
									[studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
									[studyLink setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]] forKey: @"dateAdded"];
									
									[studyLink setValue: user forKey: @"user"];
									
									@try
									{
										[user.managedObjectContext save:NULL];
									}
									@catch (NSException * e)
									{
										NSLog( @"*********** [user.managedObjectContext save:NULL]");
									}
									
									studiesArrayStudyInstanceUID = [user.studies.allObjects valueForKey:@"studyInstanceUID"];
									studiesArrayPatientUID = [user.studies.allObjects valueForKey:@"patientUID"];
									
									[self.portal updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser:user.name ip: nil];
								}
							}
						}
						
						if( user.name && [[NSUserDefaults standardUserDefaults] boolForKey: @"WebServerTagUploadedStudiesWithUsername"])
						{
							for ( NSManagedObject *study in studies)
							{
								NSString *comment = [study valueForKey: @"comment"];
								
								if( comment == nil)
									comment = [NSString string];
									
								comment = [comment stringByAppendingString: NSLocalizedString( @"Uploaded by ", nil)];
								comment = [comment stringByAppendingString: user.name];
								
								[study setValue: comment forKey:@"comment"];
							}
						}
					}
					@catch( NSException *e)
					{
						N2LogStackTrace( @"********* WebPortalConnection closeFileHandleAndClean exception : %@", e);
					}
					///
				}
				else NSLog( @"****** studyInstanceUID && patientUID == nil upload POST");
				
			}
		}
	}
	
    [idatabase addFilesAtPaths: filesAccumulator postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:YES importedFiles:YES returnArray:NO];
	
	[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/osirixUnzippedFolder" error: nil];
	
	[multipartData release];	multipartData = nil;
	[postBoundary release];		postBoundary = nil;
	[POSTfilename release];		POSTfilename = nil;
}

- (void)processDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	//NSLog(@"processPostDataChunk");
	
	if (!postHeaderOK)
	{
		if (multipartData == nil)
			[self resetPOST];
		
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
		
		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {static_cast<NSUInteger>(i), static_cast<NSUInteger>(l)};
			
			// If MacOS 10.6 : we should use - (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
			
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {static_cast<NSUInteger>(dataStartIndex), static_cast<NSUInteger>(i - dataStartIndex)};
				if( i >= dataStartIndex)
				{
					dataStartIndex = i + l;
					i += l - 1;
					NSData *newData = [postDataChunk subdataWithRange:newDataRange];
					
					if ([newData length])
					{
						[multipartData addObject:newData];
					}
					else
					{
						postHeaderOK = TRUE;
						
						NSString* postInfo = [[NSString alloc] initWithBytes: [[multipartData objectAtIndex:1] bytes] length:[(NSData*) [multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
						
						[postBoundary release];
						postBoundary = [[multipartData objectAtIndex:0] copy];
						
						@try
						{
							NSRange filenameRange = [postInfo rangeOfString: @"filename"];
							NSString *extension = nil;
							
							if( filenameRange.location != NSNotFound)
							{
								NSString *filename = [postInfo substringFromIndex: filenameRange.location + filenameRange.length];
								
								NSArray *components = [filename componentsSeparatedByString: @"\""];
								
								if( components.count >= 3)
									extension = [[components objectAtIndex: 1] pathExtension];
								
								NSString* root = @"/tmp/";
								
								int inc = 1;
								
								do
								{
									POSTfilename = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebPortal Upload %d", inc++]] stringByAppendingPathExtension: extension];
								}
								while( [[NSFileManager defaultManager] fileExistsAtPath: POSTfilename]);
								
								[POSTfilename retain];
								
								NSRange fileDataRange = {static_cast<NSUInteger>(dataStartIndex), [postDataChunk length] - dataStartIndex};
								
								BOOL eof = [self checkEOF: postDataChunk range: &fileDataRange];
								
								[[NSFileManager defaultManager] createFileAtPath:POSTfilename contents: [postDataChunk subdataWithRange:fileDataRange] attributes:nil];
								NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:POSTfilename] retain];
								
								if (file)
								{
									[file seekToEndOfFile];
									[multipartData addObject:file];
								}
								else NSLog( @"***** Failed to create file - processDataChunk : %@", POSTfilename);
								
								if (eof)
								{
									// Finished in one short? No multiparts finally...
									[self closeFileHandleAndClean];
									[self resetPOST];
								}
								
								[file release];
							}
						}
						@catch (NSException *e)
						{
							NSLog( @"******* POST processDataChunk : %@", e);
						}
						[postInfo release];
						
						break;
					}
				}
			}
		}
		
		// For other POST, like account update
		
		if ([postDataChunk length] < 4096)
		{
			[multipartData release];
			multipartData = [[NSMutableArray array] retain];
			[multipartData addObject: postDataChunk];
		}
	}
	else
	{
		NSRange fileDataRange = { 0, [postDataChunk length]};
		
		BOOL eof = [self checkEOF: postDataChunk range: &fileDataRange];
		
		@try
		{
			if( [[multipartData lastObject] isKindOfClass: [NSFileHandle class]])
				[(NSFileHandle*)[multipartData lastObject] writeData: [postDataChunk subdataWithRange: fileDataRange]];
			else
			{
				NSLog( @"******* we should not be here - processDataChunk Error");
				[self resetPOST];
			}

		}
		@catch (NSException * e)
		{
			NSLog( @"******* writeData processDataChunk exception: %@", e);
			[self resetPOST];
		}
		
		if (eof)
		{
			[self closeFileHandleAndClean];
			[self resetPOST];
		}
	}
}

#pragma mark Session, custom authentication

-(BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
	[self resetPOST];
	
	return [super onSocketWillConnect:sock];
}

- (void) fillSessionAndUserVariables
{
	NSString* method = [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(request)) autorelease];
	NSString* url = [[(id)CFHTTPMessageCopyRequestURL(request) autorelease] relativeString];
	DLog(@"HTTP %@ %@", method, url);
	
//	NSDictionary* headers = [(id)CFHTTPMessageCopyAllHeaderFields(request) autorelease];
//	NSLog(@"HEADERS: %@", headers);
	
	
	NSArray* cookies = [[(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Cookie") autorelease] componentsSeparatedByString:@"; "];
	for (NSString* cookie in cookies) {
		// cookie = [cookie stringByTrimmingStartAndEnd];
		NSArray* cookieBits = [cookie componentsSeparatedByString:@"="];
		if (cookieBits.count == 2 && [[cookieBits objectAtIndex:0] isEqualToString:SessionCookieName])
        {
			WebPortalSession* temp = [self.portal sessionForId:[cookieBits objectAtIndex:1]];
			if (temp)
                self.session = temp;
		}
	}
	
	if ([method isEqualToString:@"GET"])
    { // GET... check for tokens
		NSString* url = [[NSMakeCollectable(CFHTTPMessageCopyRequestURL(request)) autorelease] relativeString];
		NSArray* urlComponenents = [url componentsSeparatedByString:@"?"];
		if (urlComponenents.count > 1)
        {
			NSDictionary* params = [WebPortalConnection ExtractParams:urlComponenents.lastObject];
			NSString* username = [params objectForKey:@"username"];
			NSString* token = [params objectForKey:@"token"];
//            NSString* sha1 = [params objectForKey:@"sha1"];
            
			if (username && token) // has token, user exists
            {
				if( [url hasPrefix: @"/movie."])
                    self.session = [self.portal sessionForUsername:username token:token doConsume: NO]; //We keep the token valid for video players...iOS uses multiple range GET requests
                else
                    self.session = [self.portal sessionForUsername:username token:token];
            }
            else if( token)
            {
                WebPortalSession* temp = [self.portal sessionForId: [token uppercaseString]];
                if (temp)
                    self.session = temp;
            }
            
//            else if( username && sha1 && token == nil) //username and password in http request : major security breach... no way to tell the web browser to not store the URL in the history -- http://stackoverflow.com/questions/3178715/
//            {
//                if (username.length && sha1.length)
//                {
//                    NSString *userInternalPassword = [self passwordForUser: username];
//                    
//                    [self.user convertPasswordToHashIfNeeded];
//                    
//                    NSString* sha1internal = self.user.passwordHash;
//                    
//                    if( [sha1internal length] > 0 && [sha1 compare:sha1internal options:NSLiteralSearch|NSCaseInsensitiveSearch] == NSOrderedSame)
//                    {
//                        [self.session setObject:username forKey:SessionUsernameKey];
//                        [self.session deleteChallenge];
//                        [self.portal updateLogEntryForStudy:NULL withMessage:[NSString stringWithFormat: @"Successful login for user name: %@", username] forUser:NULL ip:asyncSocket.connectedHost];
//                    }
//                    else
//                    {
//                        [NSThread sleepForTimeInterval: 2]; // To avoid brute-force attacks
//                        
//                        [self.portal updateLogEntryForStudy:NULL withMessage:[NSString stringWithFormat: @"Unsuccessful login attempt with invalid password for user name: %@", username] forUser:NULL ip:asyncSocket.connectedHost];
//                    }
//                }
//            }
		}
	}
	
	if ([method isEqualToString:@"POST"] && multipartData.count == 1) // POST auth ?
	{
		NSData* data = multipartData.lastObject;
		NSString* paramsString = [[[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding] autorelease];
		NSDictionary* params = [WebPortalConnection ExtractParams:paramsString];
		
		if ([params objectForKey:@"login"])
        {
            NSString* username = [params objectForKey:@"username"];
            NSString* sha1 = [params objectForKey:@"sha1"];
            
            BOOL authenticatedByPlugin = NO;
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AllowPluginAuthenticationForWebPortal"]) // Authentication through a plugin? For example, add an LDAP plugin...
            {
                for (id key in [PluginManager plugins])
                {
                    id plugin = [[PluginManager plugins] objectForKey:key];
                    
                    if ([plugin respondsToSelector:@selector(authenticateConnection: parameters:)])
                    {
                        WebPortalUser *u = [plugin performSelector: @selector(authenticateConnection: parameters:) withObject: self withObject: params];
                        
                        if( u)
                        {
                            authenticatedByPlugin = YES;
                            
                            self.user = u;
                            
                            [self.session setObject: self.user.objectID forKey:SessionUserIDKey];
                            [self.session setObject: self.user.name forKey:SessionUsernameKey];
                            [self.session deleteChallenge];
                            [self.portal updateLogEntryForStudy:NULL withMessage:[NSString stringWithFormat: @"Successful login (plugin) for user name: %@", self.user.name] forUser:NULL ip:asyncSocket.connectedHost];
                        }
                    }
                }
            }
            
            if( authenticatedByPlugin == NO && username.length && sha1.length)
            {
                NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName: @"User"];
                r.predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", username];
                self.user = [[self.portal.database.independentContext executeFetchRequest: r error: nil] lastObject];
                
                [self.user convertPasswordToHashIfNeeded];
                
                NSString* sha1internal = self.user.passwordHash;
                
                if( [sha1internal length] > 0 && [sha1 compare:sha1internal options:NSLiteralSearch|NSCaseInsensitiveSearch] == NSOrderedSame)
                {
                    [self.session setObject: self.user.objectID forKey:SessionUserIDKey];
                    [self.session setObject:username forKey:SessionUsernameKey];
                    [self.session deleteChallenge];
                    [self.portal updateLogEntryForStudy:NULL withMessage:[NSString stringWithFormat: @"Successful login for user name: %@", username] forUser:NULL ip:asyncSocket.connectedHost];
                }
                else
                {
                    [NSThread sleepForTimeInterval: 2]; // To avoid brute-force attacks
                    
                    [self.portal updateLogEntryForStudy:NULL withMessage:[NSString stringWithFormat: @"Unsuccessful login attempt with invalid password for user name: %@", username] forUser:NULL ip:asyncSocket.connectedHost];
                }
            }
            
			[self resetPOST];
		}
		
		if ([params objectForKey:@"logout"])
		{
            [self.session setObject: nil forKey:SessionUserIDKey];
			[self.session setObject: nil forKey:SessionUsernameKey];
			self.user = nil;
			
			[self resetPOST];
		}
	}
	
	if (session && [session objectForKey:SessionUsernameKey] && [session objectForKey:SessionUserIDKey])
    {
		self.user = (WebPortalUser*) [self.portal.database.independentContext objectWithID: [session objectForKey:SessionUserIDKey]];
        
        if( [session objectForKey: SessionLastActivityDateKey])
        {
            if( [[NSDate date] timeIntervalSinceDate: [session objectForKey: SessionLastActivityDateKey]] > [[NSUserDefaults standardUserDefaults] integerForKey: @"WebServerTimeOut"])
            {
                [self.session setObject: nil forKey:SessionUserIDKey]; // logout
                [self.session setObject: nil forKey:SessionUsernameKey]; // logout
                self.user = nil;
                
                [self resetPOST];
            }
        }
        
        [self.session setObject: [NSDate date] forKey: SessionLastActivityDateKey];
	}
    else
        self.user = nil;
}

-(void)replyToHTTPRequest {
	self.response = [[[WebPortalResponse alloc] initWithWebPortalConnection:self] autorelease];
	
	[self fillSessionAndUserVariables];
	
	NSString *webPortalDefaultTitle = [[NSUserDefaults standardUserDefaults] stringForKey: @"WebPortalTitle"];
	
	if( webPortalDefaultTitle.length == 0)
		webPortalDefaultTitle = NSLocalizedString(@"OsiriX Web Portal", @"Web Portal, general default title");
	
	[response.tokens setObject: webPortalDefaultTitle forKey:@"PageTitle"]; // the default title
	[response.tokens setObject:[WebPortalProxy createWithObject:self transformer:[InfoTransformer create]] forKey:@"Info"];
	if (user)
        [response.tokens setObject:[WebPortalProxy createWithObject:user transformer:[WebPortalUserTransformer create]] forKey:@"User"];
	if (session)
        [response.tokens setObject:session forKey:@"Session"];
	[response.tokens setObject:NSUserDefaults.standardUserDefaults forKey:@"Defaults"];
	
	[super replyToHTTPRequest];

//NSLog(@"User: %X (R: %@)", user, response.httpHeaders);
	
	self.response = nil;
	self.user = nil;
	self.session = nil;
}

-(BOOL)isAuthenticated
{
	NSString* sessionUser = [session objectForKey:SessionUsernameKey];
	if (sessionUser)
    {
		if (self.user)
			return YES;
	} else
		self.user = nil;
	
	return NO;
}

// #defines from HTTPConnection.m
#define WRITE_ERROR_TIMEOUT 240
#define HTTP_RESPONSE 30

-(void)handleAuthenticationFailed
{
	//NSLog(@"handleAuthenticationFailed user %@", user);
	
	
	//	HTTPAuthenticationRequest* auth = [[[HTTPAuthenticationRequest alloc] initWithRequest:request] autorelease];
	//	if (auth.username)
	//		[self.portal updateLogEntryForStudy:nil withMessage:[NSString stringWithFormat:@"Wrong password for user %@", auth.username] forUser:NULL ip:asyncSocket.connectedHost];
	
	[self processLoginHtml];
	
	NSData* bodyData = self.response.data;
	// Status Code 401 - Unauthorized
	CFHTTPMessageRef resp = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 401, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(resp, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", (int) bodyData.length]);
	for (NSString* key in response.httpHeaders)
		CFHTTPMessageSetHeaderFieldValue(resp, (CFStringRef)key, (CFStringRef)[response.httpHeaders objectForKey:key]);
	CFHTTPMessageSetBody(resp, (CFDataRef)bodyData);
	
	[asyncSocket writeData:[self preprocessErrorResponse:resp] withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(resp);
}

-(void)handleResourceNotFound { // also other errors, actually
	int status = response.statusCode;
	if (!status) status = 404;
	
	CFHTTPMessageRef resp = CFHTTPMessageCreateResponse(kCFAllocatorDefault, status, NULL, kCFHTTPVersion1_1);
	
	NSString* title = [NSString stringWithFormat:@"HTTP error %d", status];
	NSData* bodyData = response.data;
	bodyData = [[NSString stringWithFormat:@"<html><head><title>%@</title></head><body><h1>%@</h1>%@</body></html>", title, title, bodyData? [[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] autorelease] : @""] dataUsingEncoding:NSUTF8StringEncoding];
	
	CFHTTPMessageSetHeaderFieldValue(resp, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", (int) bodyData.length]);
	CFHTTPMessageSetBody(resp, (CFDataRef)bodyData);
	
	NSData *responseData = [self preprocessErrorResponse:resp];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(resp);
}





@end
