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


NSString* const SessionCookieName = @"OSID";
NSString* const SessionUserIDKey = @"UserID"; // NSManagedObjectID
NSString* const SessionUsernameKey = @"Username"; // NSString
NSString* const SessionTokensDictKey = @"Tokens"; // NSMutableDictionary
NSString* const SessionChallengeKey = @"Challenge"; // NSString
NSString* const SessionLastActivityDateKey = @"LastActivityDate"; // NSDate

@implementation WebPortalSession

@synthesize sid, dict;

-(id)initWithId:(NSString*)isid {
	self = [super init];
	sid = [isid retain];
	dictLock = [[NSLock alloc] init];
	dict = [[NSMutableDictionary alloc] initWithCapacity:8];
	return self;
}

-(void)dealloc {
	[dict release];
	[sid release];
	[dictLock release];
	[super dealloc];
}


-(void)setObject:(id)o forKey:(NSString*)k {
	[dictLock lock];
	if (o) [dict setObject:o forKey:k];
	else [dict removeObjectForKey:k];
	[dictLock unlock];
}

-(id)objectForKey:(NSString*)k {
	[dictLock lock];
	id value = [dict objectForKey:k];
	[dictLock unlock];
	return value;
}

-(id)valueForKey:(NSString*)key {
	return [self objectForKey:key];
}

-(NSMutableDictionary*)tokensDictionary {
	[dictLock lock];
	NSMutableDictionary* tdict = [dict objectForKey:SessionTokensDictKey];
	if (!tdict) [dict setObject: tdict = [NSMutableDictionary dictionary] forKey:SessionTokensDictKey];
	[dictLock unlock];
	return tdict;
}

-(NSString*)createToken {
	NSMutableDictionary* tokensDictionary = [self tokensDictionary];
	[dictLock lock];
	
	NSString* token;
	double tokend;
	do { // is this a dumb way to generate tokens?
		tokend = [NSDate timeIntervalSinceReferenceDate];
	} while ([[tokensDictionary allKeys] containsObject: token = [[[NSData dataWithBytes:&tokend length:sizeof(double)] md5Digest] hex]]);
	
	[tokensDictionary setObject:[NSDate date] forKey:token];
	
	[dictLock unlock];
	return token;
}

-(BOOL)containsToken:(NSString*)token {
	NSMutableDictionary* tokensDictionary = [self tokensDictionary];
	[dictLock lock];
	
	NSDate *date = [tokensDictionary objectForKey: token];
	BOOL ok = NO;
    if( date)
    {
        if( [date timeIntervalSinceNow] > -30*60) // Token are valid for 30 min
            ok = YES;
        else
            [tokensDictionary removeObjectForKey:token];
    }
    
	[dictLock unlock];
	return ok;
}

-(BOOL)consumeToken:(NSString*)token {
	NSMutableDictionary* tokensDictionary = [self tokensDictionary];
	[dictLock lock];
	
	NSDate *date = [tokensDictionary objectForKey: token];
	BOOL ok = NO;
    if( date)
    {
        if( [date timeIntervalSinceNow] > -30*60) // Token are valid for 30 min
            ok = YES;
        
        [tokensDictionary removeObjectForKey:token];
    }
	
	[dictLock unlock];
	return ok;
}

-(NSString*)newChallenge {
	double challenged = [NSDate timeIntervalSinceReferenceDate];
	NSString* challenge = [[[NSData dataWithBytes:&challenged length:sizeof(double)] md5Digest] hex];
	[dict setObject:challenge forKey:SessionChallengeKey];
	return challenge;
}

-(NSString*)challenge {
	return [self objectForKey:SessionChallengeKey];
}

-(void)deleteChallenge {
	return [dict removeObjectForKey:SessionChallengeKey];
}



@end
