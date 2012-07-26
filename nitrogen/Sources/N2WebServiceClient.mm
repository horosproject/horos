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


#import "N2WebServiceClient.h"
#import "N2Debug.h"


@implementation N2WebServiceClient
@synthesize url = _url;

-(id)initWithURL:(NSURL*)url {
	self = [super init];
	[self setUrl:url];
	return self;
}

-(void)dealloc {
	[self setUrl:NULL];
	[super dealloc];
}

+(NSString*)parametersToString:(NSDictionary*)params {
	if (params && [params count]) {
		NSMutableString* paramsString = [NSMutableString stringWithCapacity:512];
		
		for (NSString* key in params)
			[paramsString appendFormat:@"&%@=%@", key, [params objectForKey:key]]; // ToDo: urlencode
		
		return paramsString;
	}
	
	return NULL;
}

-(NSData*)requestWithURL:(NSURL*)url method:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers context:(id)context {
	if (method == HTTPGet && content) {
		NSString* contentString = [[[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding] autorelease];
		NSString* urlString = [url absoluteString];
		NSUInteger questionMarkLocation = [urlString rangeOfString:@"?"].location;
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", questionMarkLocation!=NSNotFound? [urlString substringToIndex:questionMarkLocation] : urlString, [contentString substringFromIndex:1]]];
		content = NULL;
	}
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[self processUrl:url context:context] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
	[request setHTTPMethod: method == HTTPGet ? @"GET" : @"POST" ]; 
	
	if (content) [request setHTTPBody:content];
	[request setValue: content? [NSString stringWithFormat:@"%u", (int) [content length]] : 0 forHTTPHeaderField: @"Content-Length"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	if (headers)
		for (NSString* key in headers)
			[request setValue:[headers objectForKey:key] forHTTPHeaderField:key];
	
	[request setTimeoutInterval:10];
	
	DLog(@"Sending %@ request to %@: %@", [request HTTPMethod], [request URL], content? [[[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding] autorelease] : NULL);
	
	NSError* error = NULL; 
	NSURLResponse* response;
	NSData* result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
		[NSException raise:NSGenericException format:@"[N2WebServiceClient requestWithURL:method:parameters:content:headers:] failed with error: %@", [error description]];
	if ([response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse*)response statusCode]/100 != 2) // HTTP status code ≠ (200 to 299)
		[NSException raise:NSGenericException format:@"[N2WebServiceClient requestWithURL:method:parameters:content:headers:] failed with status %d", (int) [(NSHTTPURLResponse*)response statusCode]];

	if (![self validateResult:result])
		[NSException raise:NSGenericException format:@"[N2WebServiceClient requestWithURL:method:parameters:content:headers:] received invalid result: %@", [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]];
	
//	NSLog(@"\tResult: %@", [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding]autorelease]);
	
	return result;
}

-(NSData*)requestWithMethod:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers context:(id)context {
	return [self requestWithURL:_url method:method content:content headers:headers context:context];
}

-(NSData*)requestWithMethod:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers {
	return [self requestWithMethod:method content:content headers:headers context:NULL];
}

-(NSData*)getWithParameters:(NSDictionary*)params {
	return [self requestWithMethod:HTTPGet content:[[N2WebServiceClient parametersToString:params] dataUsingEncoding:NSUTF8StringEncoding] headers:NULL context:NULL];
}

-(NSData*)postWithContent:(NSData*)content {
	return [self requestWithMethod:HTTPPost content:content headers:NULL context:NULL];
}

-(NSData*)postWithParameters:(NSDictionary*)params {
	return [self postWithContent:[[N2WebServiceClient parametersToString:params] dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSURL*)processUrl:(NSURL*)url context:(id)context {
	return url;
}

-(BOOL)validateResult:(NSData*)result {
	return YES;
}

@end
