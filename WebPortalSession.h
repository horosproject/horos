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

extern NSString* const SessionUsernameKey; // NSString

@interface WebPortalSession : NSObject {
@private
	NSMutableDictionary* dict;
	NSString* sid;
	NSLock* lock;
}

@property(readonly) NSString* sid;

+(id)create;
+(id)sessionForId:(NSString*)sid;
+(id)sessionForUsername:(NSString*)username token:(NSString*)token;

-(void)setObject:(id)o forKey:(NSString*)k;
-(id)objectForKey:(NSString*)k;

-(NSString*)createToken;
-(BOOL)consumeToken:(NSString*)token;

@end
