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

@class WebPortalConnection, WebPortalSession;

@interface WebPortalData : NSObject {
	WebPortalConnection* connection;
	WebPortalSession* session;
	
	NSDictionary* requestParams;
}

+(NSRange)string:(NSString*)string rangeOfFirstOccurrenceOfBlock:(NSString*)b;
+(void)mutableString:(NSMutableString*)string block:(NSString*)blockTag setVisible:(BOOL)visible;
+(void)mutableString:(NSMutableString*)string evaluateTokensWithDictionary:(NSDictionary*)tokens;

@end


@interface WebPortalProxy : NSObject {
	NSObject* object;
	NSArray* transformers;
}

@property(readonly, retain) NSObject* object;
@property(readonly, retain) NSArray* transformers;

+(id)createWithObject:(NSObject*)o transformer:(id)t;

@end


@interface WebPortalProxyObjectTransformer : NSObject

-(id)valueForKey:(NSString*)k object:(NSObject*)o;

@end


@interface NSMutableDictionary (WebPortalProxy)

-(void)addError:(NSString*)error;
-(void)addMessage:(NSString*)message;
-(NSArray*)errors;

@end
