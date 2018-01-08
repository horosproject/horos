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


#import "HTTPResponse.h"

@class WebPortalConnection, WebPortalSession, WebPortal;

@interface WebPortalResponse : HTTPDataResponse {
	WebPortalConnection* wpc;
	WebPortal* portal;
	NSMutableDictionary* httpHeaders;
	NSString* templateString;
	NSMutableDictionary* tokens;
	int statusCode;
}

@property(assign,readonly) WebPortalConnection* wpc;
@property(retain) NSData* data;
@property(readonly) NSMutableDictionary* httpHeaders;
@property(retain) NSString* mimeType;
@property(retain) NSString* templateString;
@property(readonly) NSMutableDictionary* tokens;
@property(assign) int statusCode;

-(id)initWithWebPortalConnection:(WebPortalConnection*)wpc;
//-(id)initWithData:(NSData*)data mime:(NSString*)mime sessionId:(NSString*)sessionId __deprecated;
-(void)setSessionId:(NSString*)sessionId;

-(void)setDataWithString:(NSString*)str;

//+(NSRange)string:(NSString*)string rangeOfFirstOccurrenceOfBlock:(NSString*)b;
//+(void)mutableString:(NSMutableString*)string block:(NSString*)blockTag setVisible:(BOOL)visible;
+(void)mutableString:(NSMutableString*)string evaluateTokensWithDictionary:(NSDictionary*)localtokens context:(id)context;

@end


@interface WebPortalProxy : NSObject {
	NSObject* object;
	NSArray* transformers;
}

@property(readonly, retain) NSObject* object;
@property(readonly, retain) NSArray* transformers;

+(id)createWithObject:(NSObject*)o transformer:(id)t;
-(id)valueForKey:(NSString*)k context:(id)context;

@end


@interface WebPortalProxyObjectTransformer : NSObject

+(id)create;
-(id)valueForKey:(NSString*)k object:(NSObject*)o context:(id)context;

@end


@interface NSMutableDictionary (WebPortalProxy)

-(void)addError:(NSString*)error;
-(void)addMessage:(NSString*)message;
-(NSMutableArray*)errors;

@end


@interface InfoTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


@interface StringTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


/*@interface ArrayTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


@interface SetTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end*/


@interface DateTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


@interface DicomStudyTransformer : WebPortalProxyObjectTransformer
+(id)create;
+ (void) clearOtherStudiesForThisPatientCache;
@end


@interface DicomSeriesTransformer : WebPortalProxyObjectTransformer {
	NSSize size;
}
+(id)create;
@end


@interface WebPortalUserTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end
