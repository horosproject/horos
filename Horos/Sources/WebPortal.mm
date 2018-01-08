/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "WebPortalDatabase.h"
#import "WebPortalSession.h"
#import "WebPortalConnection.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSUserDefaultsController+N2.h"
#import "AppController.h"
#import "NSData+N2.h"
#import "NSString+N2.h"
#import "NSFileManager+N2.h"
#import "DDData.h"
#import "DicomDatabase.h"
#import "N2Debug.h"
#import "CSMailMailClient.h"
#import "NSString+SymlinksAndAliases.h"

@interface WebPortalServer ()

@property(readwrite, assign) WebPortal* portal;

@end

@interface WebPortalServer (Dummy)

- (void)ignore:(id)dummy;

@end

@implementation WebPortalServer

@synthesize portal;

- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
	// Figure out what thread/runloop to run the new connection on.
	// We choose the thread/runloop with the lowest number of connections.
	
	uint m = 0;
	NSRunLoop *mLoop = nil;
	uint mLoad = 0;
	
	@synchronized( [portal runLoops])
	{
		mLoop = [[portal runLoops] objectAtIndex:0];
		mLoad = [[[portal runLoopsLoad] objectAtIndex:0] unsignedIntValue];
		
		uint i;
		for(i = 1; i < THREAD_POOL_SIZE; i++)
		{
			uint iLoad = [[[portal runLoopsLoad] objectAtIndex:i] unsignedIntValue];
			
			if(iLoad < mLoad)
			{
				m = i;
				mLoop = [[portal runLoops] objectAtIndex:i];
				mLoad = iLoad;
			}
		}
		
		[[portal runLoopsLoad] replaceObjectAtIndex:m withObject:[NSNumber numberWithUnsignedInt:(mLoad + 1)]];
		
//		NSLog(@"Updating run loop %u with load %@", m, mLoad + 1);
	}
	// And finally, return the proper run loop
	return mLoop;
}

/**
 * This method is automatically called when a HTTPConnection dies.
 * We need to update the number of connections per thread.
 **/
- (void)connectionDidDie:(NSNotification *)notification
{
	// Note: This method is called on the thread/runloop that posted the notification
	
	@synchronized( [portal runLoops])
	{
		unsigned int runLoopIndex = [[portal runLoops] indexOfObject:[NSRunLoop currentRunLoop]];
		
		if(runLoopIndex < [[portal runLoops] count])
		{
			unsigned int runLoopLoad = [[[portal runLoopsLoad] objectAtIndex:runLoopIndex] unsignedIntValue];
			
			NSNumber *newLoad = [NSNumber numberWithUnsignedInt:(runLoopLoad - 1)];
			
			[[portal runLoopsLoad] replaceObjectAtIndex:runLoopIndex withObject:newLoad];
			
//			NSLog(@"Updating run loop %u with load %@", runLoopIndex, newLoad);
		}
	}
	
	// Don't forget to call super, or the connection won't get proper deallocated!
	[super connectionDidDie:notification];
}

@end


@interface WebPortal ()

@property(readwrite, retain) WebPortalDatabase* database;
@property(readwrite, retain) DicomDatabase* dicomDatabase;
@property(readwrite, retain) NSMutableDictionary* cache;
@property(readwrite, retain) NSMutableDictionary* locks;
@property(readwrite) BOOL isAcceptingConnections;

@end


@implementation WebPortal

@synthesize sessions;

static NSString* DefaultWebPortalDatabasePath = nil;

+(void)initialize
{
    #ifdef MACAPPSTORE
	DefaultWebPortalDatabasePath = [[NSString alloc] initWithString: [@"~/Library/Application Support/Horos App/WebUsers.sql" stringByExpandingTildeInPath]];
    #else
    DefaultWebPortalDatabasePath = [[NSString alloc] initWithString: [@"~/Library/Application Support/Horos/WebUsers.sql" stringByExpandingTildeInPath]];
    #endif
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWadoServiceEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
}

#ifndef OSIRIX_LIGHT
+(void)initializeWebPortalClass { // called from AppController
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalPortNumberDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalAddressDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalUsesSSLDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalPrefersCustomWebPagesKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalRequiresAuthenticationDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalUsersCanRestorePasswordDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalUsesWeasisDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalPrefersFlashDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWadoServiceEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
    
	// last because this starts the listener
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];

	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalNotificationsIntervalDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalNotificationsEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultWebPortal];
    
    if (NSUserDefaults.webPortalEnabled)
        [CSMailMailClient mailClient]; //If authentication is required to read email password: ask it now !
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"wadoOnlyServer"])
    {
        WebPortal *w = self.wadoOnlyWebPortal;
        
        w.usesSSL = NO;
        w.portNumber = [[NSUserDefaults standardUserDefaults] integerForKey: @"wadoOnlyServerPort"];
        w.address = [[NSUserDefaults standardUserDefaults] stringForKey: @"wadoOnlyServerURL"];
        w.authenticationRequired = NO;
        w.weasisEnabled = NO;
        w.flashEnabled = NO;
        w.wadoEnabled = YES;
        w.notificationsEnabled = NO;
        [w startAcceptingConnections];
    }
}
#endif

+(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (!context) {
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWadoServiceEnabledDefaultsKey)])
			if (!NSUserDefaults.wadoServiceEnabled)
				[NSUserDefaultsController.sharedUserDefaultsController setBool:NO forKey:OsirixWebPortalUsesWeasisDefaultsKey];
	} else {
		WebPortal* webPortal = (id)context;
		
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalEnabledDefaultsKey)])
			if (NSUserDefaults.webPortalEnabled)
				[webPortal startAcceptingConnections];
			else [webPortal stopAcceptingConnections];
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalUsesSSLDefaultsKey)])
			webPortal.usesSSL = NSUserDefaults.webPortalUsesSSL;
		else

		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalPortNumberDefaultsKey)])
			webPortal.portNumber = NSUserDefaults.webPortalPortNumber;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalAddressDefaultsKey)])
			webPortal.address = NSUserDefaults.webPortalAddress;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalPrefersCustomWebPagesKey)])
        {
			NSMutableArray* dirsToScanForFiles = [NSMutableArray arrayWithCapacity:2];
            #ifdef MACAPPSTORE
			if (NSUserDefaults.webPortalPrefersCustomWebPages) [dirsToScanForFiles addObject: [@"~/Library/Application Support/Horos App/WebServicesHTML" stringByExpandingTildeInPath]];
            #else
            if (NSUserDefaults.webPortalPrefersCustomWebPages) [dirsToScanForFiles addObject: [@"~/Library/Application Support/Horos/WebServicesHTML" stringByExpandingTildeInPath]];
            #endif
            [dirsToScanForFiles addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WebServicesHTML"]];
			webPortal.dirsToScanForFiles = dirsToScanForFiles;
		}
        else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalRequiresAuthenticationDefaultsKey)])
			webPortal.authenticationRequired = NSUserDefaults.webPortalRequiresAuthentication;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalUsersCanRestorePasswordDefaultsKey)])
			webPortal.passwordRestoreAllowed = NSUserDefaults.webPortalUsersCanRestorePassword;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalUsesWeasisDefaultsKey)])
			webPortal.weasisEnabled = NSUserDefaults.webPortalUsesWeasis;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalPrefersFlashDefaultsKey)])
			webPortal.flashEnabled = NSUserDefaults.webPortalPrefersFlash;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWadoServiceEnabledDefaultsKey)])
			webPortal.wadoEnabled = NSUserDefaults.wadoServiceEnabled;
		else
		
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalNotificationsIntervalDefaultsKey)])
			webPortal.notificationsInterval = NSUserDefaults.webPortalNotificationsInterval;
		else
			
		if ([keyPath isEqualToString:valuesKeyPath(OsirixWebPortalNotificationsEnabledDefaultsKey)])
			webPortal.notificationsEnabled = NSUserDefaults.webPortalNotificationsEnabled;
					
	}
}

+(void)finalizeWebPortalClass {
	//	[NSUserDefaultsController.sharedUserDefaultsController removeObserver:self forValuesKey:OsirixWebPortalNotificationsIntervalDefaultsKey];
	[self.defaultWebPortal release];
}

+(WebPortal*)defaultWebPortal {
	static WebPortal* defaultWebPortal = NULL;
    
    if( DefaultWebPortalDatabasePath == nil)
        return nil;
    
	if (!defaultWebPortal)
		defaultWebPortal = [[self alloc] initWithDatabaseAtPath:DefaultWebPortalDatabasePath dicomDatabase:[DicomDatabase defaultDatabase]];
	
	return defaultWebPortal;
}

+(WebPortal*)wadoOnlyWebPortal {
	static WebPortal* wadoOnlyWebPortal = NULL;
    
    if( DefaultWebPortalDatabasePath == nil)
        return nil;
    
	if (!wadoOnlyWebPortal)
		wadoOnlyWebPortal = [[self alloc] initWithDatabaseAtPath:DefaultWebPortalDatabasePath dicomDatabase:[DicomDatabase defaultDatabase]];
	
	return wadoOnlyWebPortal;
}

#pragma mark Instance

@synthesize database, dicomDatabase, cache, locks;
@synthesize isAcceptingConnections;
@synthesize usesSSL;
@synthesize portNumber;
@synthesize address;
@synthesize dirsToScanForFiles;
@synthesize authenticationRequired;
@synthesize notificationsEnabled, notificationsInterval;

@synthesize passwordRestoreAllowed;
@synthesize wadoEnabled;
@synthesize weasisEnabled;
@synthesize flashEnabled, runLoops, runLoopsLoad;

-(id)initWithDatabase:(WebPortalDatabase*)db dicomDatabase:(DicomDatabase*)dd; {
	self = [super init];
	
	sessions = [[NSMutableArray alloc] initWithCapacity:64];
	sessionsArrayLock = [[NSLock alloc] init];
	sessionCreateLock = [[NSLock alloc] init];

	self.database = db;
	self.dicomDatabase = dd;
	self.cache = [NSMutableDictionary dictionary];
	self.locks = [NSMutableDictionary dictionary];
	
    temporaryUsersTimer = [[NSTimer scheduledTimerWithTimeInterval: 60 target:self selector:@selector(deleteTemporaryUsers:) userInfo:NULL repeats:YES] retain];
	
	preferredLocalizations = [[[NSBundle mainBundle] preferredLocalizations] copy];
    
	return self;
}

-(id)initWithDatabaseAtPath:(NSString*)sqlFilePath dicomDatabase:(DicomDatabase*)dd; {
	return [self initWithDatabase:[[[WebPortalDatabase alloc] initWithPath:DefaultWebPortalDatabasePath] autorelease] dicomDatabase:dd];
}

- (NSThread*) threadForRunLoopRef: (CFRunLoopRef) runloopref
{
	NSUInteger index = NSNotFound;
	
	for( NSRunLoop *rl in runLoops)
	{
		if( [rl getCFRunLoop] == runloopref)
		{
			index = [runLoops indexOfObject: rl];
			break;
		}
	}
	
	if( index != NSNotFound)
	{
		return [httpThreads objectAtIndex: index];
	}
	
	NSLog( @"******* threadForRunLoop runloop not found !");
	
	return nil;
}

-(void)invalidate
{
	[self stopAcceptingConnections];
}

-(void)dealloc
{
	[self invalidate];
	
	[notificationsTimer invalidate];
    [notificationsTimer release];
    notificationsTimer = nil;
    
    [temporaryUsersTimer invalidate];
    [temporaryUsersTimer release];
    temporaryUsersTimer = nil;
    
	self.notificationsEnabled = NO;
	
	self.database = NULL;
	self.dicomDatabase = NULL;
	self.cache = NULL;
	self.locks = NULL;
	
	[httpThreads release];
	[runLoopsLoad release];
	[runLoops release];
	[sessionCreateLock release];
	[sessionsArrayLock release];
	[sessions release];
	
	self.address = NULL;
	self.dirsToScanForFiles = NULL;
	
	[preferredLocalizations release];
	
	[super dealloc];
}

-(void)restartIfRunning {
	if (isAcceptingConnections) {
		NSLog( @"----- cannot restart web server -> you have to restart Horos");
//		[self stopAcceptingConnections];
//		[self startAcceptingConnections];
	}
}

-(void)setPortNumber:(NSInteger)n {
	if (n != portNumber) {
		portNumber = n;
		[self restartIfRunning];
	}
}

-(void)setUsesSSL:(BOOL)b {
	if (b != usesSSL) {
		usesSSL = b;
		[self restartIfRunning];
	}
}

// This is the main thread for the socket connections, then, the connections are distributed in our thread pool
- (void) startServerThread
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [NSThread currentThread].name = @"WebPortal server thread";
    
	// Start threads
	uint i;
	for(i = 0; i < THREAD_POOL_SIZE; i++)
	{
		[NSThread detachNewThreadSelector:@selector(connectionsThread:) toTarget: self withObject: [NSNumber numberWithUnsignedInt:i]];
	}
	
	NSError* err = NULL;
	if (![server start: &err])
	{
		NSLog(@"Exception: [WebPortal startAcceptingConnectionsThread:] %@", err);
		[AppController.sharedAppController performSelectorOnMainThread:@selector(displayError:) withObject:NSLocalizedString(@"Cannot start Web Server. TCP/IP port is probably already used by another process.", NULL) waitUntilDone:YES];
		return;
	}
	
	while (!NSThread.currentThread.isCancelled)
	{
		NSAutoreleasePool *runloopPool = [[NSAutoreleasePool alloc] init];
		@try
		{
			[NSRunLoop.currentRunLoop runMode: NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
		}
		@catch (NSException * e) {
            N2LogExceptionWithStackTrace(e);
        }
		
		[runloopPool release];
	}
	
	[server stop];
	
	NSLog(@"[WebPortal startServerThread:] finishing");
	
	[pool release];
}

-(void)startAcceptingConnections {
	if (!isAcceptingConnections) {
		@try {
			// Initialize an array to reference all the threads
			runLoops = [[NSMutableArray alloc] initWithCapacity:THREAD_POOL_SIZE];
			
			// Initialize an array to hold the number of connections being processed for each thread
			runLoopsLoad = [[NSMutableArray alloc] initWithCapacity:THREAD_POOL_SIZE];
			
			httpThreads = [[NSMutableArray alloc] initWithCapacity:THREAD_POOL_SIZE];
			
			server = [[WebPortalServer alloc] init];
			server.portal = self;
			
			server.connectionClass = [WebPortalConnection class];
			
			if (self.usesSSL)
				server.type = @"_https._tcp.";
			else server.type = @"_http._tcp.";
			
			server.TXTRecordDictionary = [NSDictionary dictionaryWithObject:@"OsiriX" forKey:@"ServerType"];
			server.port = self.portNumber;
			server.documentRoot = [NSURL fileURLWithPath:[@"~/Sites" stringByExpandingTildeInPath]];
			
			if( serverThread)
				[serverThread release];
				
			serverThread = [[NSThread alloc] initWithTarget: self selector: @selector(startServerThread) object: nil];
			
			[serverThread start];
			
		} @catch (NSException * e) {
			NSLog(@"Exception: [WebPortal startAcceptingConnections] %@", e);
		}
	}
}

-(void)connectionsThread:(id)obj
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    [NSThread currentThread].name = @"WebPortal connection thread";
    
	@try
    {
		@synchronized(runLoops)
		{
			[runLoops addObject:[NSRunLoop currentRunLoop]];
			[runLoopsLoad addObject:[NSNumber numberWithUnsignedInt:0]];
			[httpThreads addObject: NSThread.currentThread];
		}
		
		isAcceptingConnections = YES;
		[NSRunLoop.currentRunLoop addTimer:[NSTimer scheduledTimerWithTimeInterval:DBL_MAX target:self selector:@selector(ignore:) userInfo:NULL repeats:NO] forMode: NSDefaultRunLoopMode];
		while (!NSThread.currentThread.isCancelled)
		{
			@autoreleasepool {
                [NSRunLoop.currentRunLoop runMode: NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
			}
		}
		NSLog(@"[WebPortal connectionsThread:] finishing");
	} @catch (NSException* e) {
		NSLog(@"Warning: [WebPortal connetionsThread] %@", e);
	} @finally {
		[pool release];
	}
}

-(void)stopAcceptingConnections {
	if (isAcceptingConnections) {
		isAcceptingConnections = NO;
//		@try 
//		{
//			[serverThread cancel];
//			[NSThread sleepForTimeInterval: 5];
//			
//			for( NSThread *thread in httpThreads)
//				[thread cancel];
//			
//		} @catch (NSException* e) {
//			NSLog(@"Exception: [WebPortal stopAcceptingConnections] %@", e);
//		}
        
        [notificationsTimer invalidate];
        [notificationsTimer release];
        notificationsTimer = nil;
        
        [temporaryUsersTimer invalidate];
        [temporaryUsersTimer release];
        temporaryUsersTimer = nil;
        
		NSLog( @"----- cannot stop web server -> you have to restart Horos");
	}
	
}

-(NSData*)dataForPath:(NSString*)file {
	NSMutableArray* dirsToScanForFile = [[self.dirsToScanForFiles mutableCopy] autorelease];
	
	const NSString* const DefaultLanguage = @"English";
	BOOL isDirectory;
	
	for (NSInteger i = 0; i < dirsToScanForFile.count; ++i) {
		NSString* path = [[dirsToScanForFile objectAtIndex:i] stringByResolvingSymlinksAndAliases];
		
		// path not on disk, ignore
		if (![[NSFileManager defaultManager] fileExistsAtPath: path isDirectory:&isDirectory] || !isDirectory) {
			[dirsToScanForFile removeObjectAtIndex:i];
			--i; continue;
		}
		
		// path exists, look for a localized subdir first, otherwise in the dir itself
		
		for (NSString* lang in [preferredLocalizations arrayByAddingObject:DefaultLanguage]) {
			NSString* langPath = [path stringByAppendingPathComponent:lang];
			if ([[NSFileManager defaultManager] fileExistsAtPath: langPath isDirectory:&isDirectory] && isDirectory) {
				[dirsToScanForFile insertObject:langPath atIndex:i];
				++i; break;
			}
		}
	}
	
	for (NSString* dirToScanForFile in dirsToScanForFile) {
		NSString* path = [dirToScanForFile stringByAppendingPathComponent:file];
		@try {
			NSData* data = [NSData dataWithContentsOfFile: path];
			if (data) return data;
		} @catch (NSException* e) {
			// do nothing, just try next
		}
	}
    
	//	NSLog( @"****** File not found: %@", file);
	
	return NULL;
}

-(NSString*)stringForPath:(NSString*)file {
	NSData* data = [self dataForPath:file];
	if (!data) {
		NSLog(@"Warning: [WebPortal stringForPath] is returning NULL for %@", file);
		return NULL;
	}
	
	NSMutableString* html = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	NSRange range;
	while ((range = [html rangeOfString:@"%INCLUDE:"]).length) {
		NSRange rangeEnd = [html rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(range.location+range.length, html.length-(range.location+range.length))];
		NSString* replaceFilename = [html substringWithRange:NSMakeRange(range.location+range.length, rangeEnd.location-(range.location+range.length))];
		NSString* replaceFilepath = [file stringByComposingPathWithString:replaceFilename];
		[html replaceCharactersInRange:NSMakeRange(range.location, rangeEnd.location+rangeEnd.length-range.location) withString:N2NonNullString([self stringForPath:replaceFilepath])];
	}
	
	return [html autorelease];
}

-(NSString*)URL // This is the public URL (see OSIWebPreferences) - it can be different of the real address
{
    NSString *add = self.address;
    NSString *protocol = nil;
    
    //The user can "force" to have a different public address, compared to the 'real' address (usefull for port forwarding)
    //Search if the protocol and port are specified
    
    if( [add hasPrefix: @"http://"])
    {
        protocol = @"http://";
        add = [add substringFromIndex: protocol.length];
    }
    
    if( [add hasPrefix: @"https://"])
    {
        protocol = @"https://";
        add = [add substringFromIndex: protocol.length];
    }
    
    if( protocol == nil)
    {
        if( self.usesSSL)
            protocol = @"https://";
        else
            protocol = @"http://";
    }
    
    if( ![add contains:@":"])
    {
        BOOL isDefaultPort = NO;
        if ([protocol isEqualToString: @"http://"] && self.portNumber == 80) isDefaultPort = YES;
        if ([protocol isEqualToString: @"https://"] && self.portNumber == 443) isDefaultPort = YES;
        
        if (!isDefaultPort)
            add = [add stringByAppendingFormat:@":%d", (int) self.portNumber];
    }
    else
    {
        if ([protocol isEqualToString: @"http://"] && [add hasSuffix:@":80"])
            add = [add substringWithRange:NSMakeRange(0,add.length-3)];
        
        if ([protocol isEqualToString: @"https://"] && [add hasSuffix:@":443"])
            add = [add substringWithRange:NSMakeRange(0,add.length-4)];
    }
    
	return [NSString stringWithFormat: @"%@%@", protocol, add];
}

/*-(NSString*)URLForAddress:(NSString*)add {
	if (!add)
		add = self.address;
	
	NSString* protocol = self.usesSSL? @"https" : @"http";
	
	if (![add contains:@":"]) {
		BOOL isDefaultPort = NO;
		if (!self.usesSSL && self.portNumber == 80) isDefaultPort = YES;
		if (self.usesSSL && self.portNumber == 443) isDefaultPort = YES;
		
		if (!isDefaultPort)
			add = [add stringByAppendingFormat:@"%d", self.portNumber];
	}
	
	return [NSString stringWithFormat: @"%@://%@", protocol, add];
}*/

#pragma mark Sessions

-(id)sessionForId:(NSString*)sid {
	[sessionsArrayLock lock];
	WebPortalSession* session = NULL;
	
	for (WebPortalSession* isession in sessions)
		if ([isession.sid isEqualToString:sid]) {
			session = isession;
			break;
		}
	
	[sessionsArrayLock unlock];
	return session;
}


-(id)sessionForUsername:(NSString*)username token:(NSString*)token
{
	return [self sessionForUsername: username token: token doConsume: YES];
}

-(id)sessionForUsername:(NSString*)username token:(NSString*)token doConsume: (BOOL) doConsume
{
    [sessionsArrayLock lock];
	WebPortalSession* session = NULL;
	
	for (WebPortalSession* isession in sessions)
    {
        if( doConsume)
        {
            if ([[isession objectForKey:SessionUsernameKey] isEqualToString:username] && [isession consumeToken:token]) {
                session = isession;
                break;
            }
        }
        else
        {
            if ([[isession objectForKey:SessionUsernameKey] isEqualToString:username] && [isession containsToken:token]) {
                session = isession;
                break;
            }
        }
	}
	[sessionsArrayLock unlock];
	return session;    
}

-(WebPortalSession*)addSession:(NSString*) sid
{
    WebPortalSession* session = [[[WebPortalSession alloc] initWithId:sid] autorelease];
    
	[sessionsArrayLock lock];
	[sessions addObject:session];
	[sessionsArrayLock unlock];
    
    return session;
}

-(id)newSession
{
	[sessionCreateLock lock];
	
	NSString* sid;
	long sidd;
	do { // is this a dumb way to generate SIDs?
		sidd = random();
	} while ([self sessionForId: sid = [[[NSData dataWithBytes:&sidd length:sizeof(long)] md5Digest] hex]]);
	
    WebPortalSession* session = [self addSession: sid];
    
	[sessionCreateLock unlock];
    
	return session;
}

#pragma mark Notifications

-(void)setNotificationsEnabled:(BOOL)flag
{
	if (self.notificationsEnabled != flag)
    {
		notificationsEnabled = flag;
		if (!flag)
        {
			[notificationsTimer invalidate];
            [notificationsTimer release];
			notificationsTimer = nil;
		}
        else if( self.notificationsInterval > 0)
			notificationsTimer = [[NSTimer scheduledTimerWithTimeInterval:self.notificationsInterval*60 target:self selector:@selector(notificationsTimerCallback:) userInfo:NULL repeats:YES] retain];
	}
}

-(void)setNotificationsInterval:(NSInteger)value
{
	if (self.notificationsInterval != value)
    {
		notificationsInterval = value;
		if (self.notificationsEnabled)
        {
			[notificationsTimer invalidate];
            [notificationsTimer release];
            notificationsTimer = nil;
            
            if( self.notificationsInterval > 0)
                notificationsTimer = [[NSTimer scheduledTimerWithTimeInterval:self.notificationsInterval*60 target:self selector:@selector(notificationsTimerCallback:) userInfo:NULL repeats:YES] retain];
		}
	}
}

-(void)notificationsTimerCallback:(NSTimer*)timer
{
	if (self.isAcceptingConnections)
		[self emailNotifications];
}

@end



