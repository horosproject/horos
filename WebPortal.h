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
#import "HTTPServer.h"

@class WebPortalDatabase, WebPortalSession, WebPortalServer, DicomDatabase;

#define THREAD_POOL_SIZE 4

@interface WebPortal : NSObject {
@private
	WebPortalDatabase* database;
	DicomDatabase* dicomDatabase;
	BOOL isAcceptingConnections;
	NSMutableArray* sessions;
	NSLock* sessionsArrayLock;
	NSLock* sessionCreateLock;
	BOOL usesSSL;
	NSInteger portNumber;
	NSString* address;
	NSArray* dirsToScanForFiles;
	BOOL authenticationRequired;
	BOOL passwordRestoreAllowed;
	BOOL wadoEnabled;
	BOOL weasisEnabled;
	BOOL flashEnabled;
	
	BOOL notificationsEnabled;
	NSInteger notificationsInterval;
	NSTimer* notificationsTimer;
	
	NSMutableDictionary* cache;
	NSMutableDictionary* locks;
	NSMutableArray *runLoops, *runLoopsLoad, *httpThreads;
	WebPortalServer *server;
	NSThread *serverThread;
	
	NSMutableDictionary *seriesForUsersCache;
}

// called from AppController
+(void)applicationWillFinishLaunching;
+(void)applicationWillTerminate;

+(WebPortal*)defaultWebPortal;

@property(readonly, retain) WebPortalDatabase* database;
@property(readonly, retain) DicomDatabase* dicomDatabase;
@property(readonly, retain) NSMutableDictionary* cache;
@property(readonly, retain) NSMutableDictionary* locks;

@property(readonly) BOOL isAcceptingConnections;

@property(readonly) NSMutableArray *runLoops, *runLoopsLoad;

@property BOOL usesSSL;
@property NSInteger portNumber;
@property(retain) NSString* address;

@property(retain) NSArray* dirsToScanForFiles;

@property BOOL authenticationRequired;
@property BOOL passwordRestoreAllowed;

@property BOOL wadoEnabled;
@property BOOL weasisEnabled;
@property BOOL flashEnabled;

@property BOOL notificationsEnabled;
@property NSInteger notificationsInterval;

-(id)initWithDatabase:(WebPortalDatabase*)database dicomDatabase:(DicomDatabase*)dd;
-(id)initWithDatabaseAtPath:(NSString*)sqlFilePath dicomDatabase:(DicomDatabase*)dd;

-(void)startAcceptingConnections;
-(void)stopAcceptingConnections;

- (NSThread*) threadForRunLoopRef: (CFRunLoopRef) runloopref;

-(NSData*)dataForPath:(NSString*)rel;
-(NSString*)stringForPath:(NSString*)file;

-(WebPortalSession*)newSession;
-(WebPortalSession*)sessionForId:(NSString*)sid;
-(WebPortalSession*)sessionForUsername:(NSString*)username token:(NSString*)token;

-(NSString*)addressWithPortUnlessDefault;
-(NSString*)URL;
//-(NSString*)URLForAddress:(NSString*)address;

@end


@interface WebPortalServer : HTTPServer {
	WebPortal* portal;
}

@property(readonly, assign) WebPortal* portal;

@end