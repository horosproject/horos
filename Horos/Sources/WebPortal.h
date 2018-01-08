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
