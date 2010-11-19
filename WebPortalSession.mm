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

#import "WebPortalSession.h"
#import "DDData.h"
#import "NSData+N2.h"


NSString* const SessionCookieName = @"SID";

@implementation WebPortalSession

static NSMutableArray* Sessions = NULL;
static NSLock* SessionsArrayLock = NULL;
static NSLock* SessionCreateLock = NULL;

+(void)initialize {
	Sessions = [[NSMutableArray alloc] initWithCapacity:64];
	SessionsArrayLock = [[NSLock alloc] init];
	SessionCreateLock = [[NSLock alloc] init];
}

@synthesize sid;

-(id)initWithId:(NSString*)isid {
	self = [super init];
	sid = [isid retain];
	lock = [[NSLock alloc] init];
	dict = [[NSMutableDictionary alloc] initWithCapacity:8];
	return self;
}

-(void)dealloc {
	[dict release];
	[sid release];
	[lock release];
	[super dealloc];
}

NSString* const SessionUsernameKey = @"Username"; // NSString
NSString* const SessionTokensDictKey = @"Tokens"; // NSMutableDictionary

+(id)sessionForId:(NSString*)sid {
	[SessionsArrayLock lock];
	WebPortalSession* session = NULL;
	
	for (WebPortalSession* isession in Sessions)
		if ([isession.sid isEqual:sid]) {
			session = isession;
			break;
		}
	
	[SessionsArrayLock unlock];
	return session;
}

+(id)sessionForUsername:(NSString*)username token:(NSString*)token {
	[SessionsArrayLock lock];
	WebPortalSession* session = NULL;
	
	for (WebPortalSession* isession in Sessions)
		if ([[isession objectForKey:SessionUsernameKey] isEqual:username] && [isession consumeToken:token]) {
			session = isession;
			break;
		}
	
	[SessionsArrayLock unlock];
	return session;
}

+(id)create {
	[SessionCreateLock lock];

	NSString* sid;
	long sidd;
	do { // is this a dumb way to generate SIDs?
		sidd = random();
	} while ([self sessionForId: sid = [[[NSData dataWithBytes:&sidd length:sizeof(long)] md5Digest] hex]]);
	
	WebPortalSession* session = [[WebPortalSession alloc] initWithId:sid];
	[SessionsArrayLock lock];
	[Sessions addObject:session];
	[SessionsArrayLock unlock];
	[session release];
	
	[SessionCreateLock unlock];
	return session;
}

-(void)setObject:(id)o forKey:(NSString*)k {
	[lock lock];
	if (o) [dict setObject:o forKey:k];
	else [dict removeObjectForKey:k];
	[lock unlock];
}

-(id)objectForKey:(NSString*)k {
	[lock lock];
	id value = [dict objectForKey:k];
	[lock unlock];
	return value;
}

-(NSMutableDictionary*)tokensDictionary {
	[lock lock];
	NSMutableDictionary* tdict = [dict objectForKey:SessionTokensDictKey];
	if (!tdict) [dict setObject: tdict = [NSMutableDictionary dictionary] forKey:SessionTokensDictKey];
	[lock unlock];
	return tdict;
}

-(NSString*)createToken {
	NSMutableDictionary* tokensDictionary = [self tokensDictionary];
	[lock lock];
	
	NSString* token;
	double tokend;
	do { // is this a dumb way to generate tokens?
		tokend = [NSDate timeIntervalSinceReferenceDate];
	} while ([[tokensDictionary allKeys] containsObject: token = [[[NSData dataWithBytes:&tokend length:sizeof(double)] md5Digest] hex]]);
	
	[tokensDictionary setObject:[NSDate date] forKey:token];
	
	[lock unlock];
	return token;
}

-(BOOL)consumeToken:(NSString*)token {
	NSMutableDictionary* tokensDictionary = [self tokensDictionary];
	[lock lock];
	
	BOOL ok = [[tokensDictionary allKeys] containsObject:token];
	if (ok) [tokensDictionary removeObjectForKey:token];
	
	[lock unlock];
	return ok;
}

@end
