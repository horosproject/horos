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
	NSTimer* notificationsTimer, *temporaryUsersTimer;
	
	NSArray *preferredLocalizations;
	NSMutableDictionary* cache;
	NSMutableDictionary* locks;
	NSMutableArray *runLoops, *runLoopsLoad, *httpThreads;
	WebPortalServer *server;
	NSThread *serverThread;
	
//	NSMutableDictionary *seriesForUsersCache;
}

// called from AppController
+(void)initializeWebPortalClass;
+(void)finalizeWebPortalClass;

+(WebPortal*)defaultWebPortal;
+(WebPortal*)wadoOnlyWebPortal;

@property(readonly, retain) WebPortalDatabase* database;
@property(readonly, retain) DicomDatabase* dicomDatabase;
@property(readonly, retain) NSMutableDictionary* cache;
@property(readonly, retain) NSMutableDictionary* locks;
@property(readonly, retain) NSMutableArray* sessions;

@property(readonly) BOOL isAcceptingConnections;

@property(readonly) NSMutableArray *runLoops, *runLoopsLoad;

@property (nonatomic) BOOL usesSSL;
@property (nonatomic) NSInteger portNumber;
@property(retain) NSString* address;

@property(retain) NSArray* dirsToScanForFiles;

@property BOOL authenticationRequired;
@property BOOL passwordRestoreAllowed;

@property BOOL wadoEnabled;
@property BOOL weasisEnabled;
@property BOOL flashEnabled;

@property (nonatomic) BOOL notificationsEnabled;
@property (nonatomic) NSInteger notificationsInterval;

-(id)initWithDatabase:(WebPortalDatabase*)database dicomDatabase:(DicomDatabase*)dd;
-(id)initWithDatabaseAtPath:(NSString*)sqlFilePath dicomDatabase:(DicomDatabase*)dd;

-(void)startAcceptingConnections;
-(void)stopAcceptingConnections;

- (NSThread*) threadForRunLoopRef: (CFRunLoopRef) runloopref;

-(NSData*)dataForPath:(NSString*)rel;
-(NSString*)stringForPath:(NSString*)file;

-(WebPortalSession*)newSession;
-(WebPortalSession*)addSession:(NSString*) sid;
-(WebPortalSession*)sessionForId:(NSString*)sid;
-(WebPortalSession*)sessionForUsername:(NSString*)username token:(NSString*)token;
-(id)sessionForUsername:(NSString*)username token:(NSString*)token doConsume: (BOOL) doConsume;

-(NSString*)URL;
//-(NSString*)URLForAddress:(NSString*)address;

@end


@interface WebPortalServer : HTTPServer {
	WebPortal* portal;
}

@property(readonly, assign) WebPortal* portal;

@end
