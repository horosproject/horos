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

enum HTTPMethod {
	HTTPGet,
	HTTPPost
};

@interface N2WebServiceClient : NSObject {
	NSURL* _url;
}

@property(retain) NSURL* url;

-(id)initWithURL:(NSURL*)url;

-(NSData*)requestWithURL:(NSURL*)url method:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers context:(id)context;
-(NSData*)requestWithMethod:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers;
-(NSData*)requestWithMethod:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers context:(id)context;
-(NSData*)getWithParameters:(NSDictionary*)params;
-(NSData*)postWithContent:(NSData*)content;
-(NSData*)postWithParameters:(NSDictionary*)params;

-(NSURL*)processUrl:(NSURL*)url context:(id)context;
-(BOOL)validateResult:(NSData*)result;

@end
