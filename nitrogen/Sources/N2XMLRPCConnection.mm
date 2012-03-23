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

#import "N2XMLRPCConnection.h"
#import "N2Debug.h"
#import "N2XMLRPC.h"

#import "N2Shell.h"

@implementation N2XMLRPCConnection
@synthesize delegate = _delegate;

-(void)dealloc {
	[self setDelegate:NULL];
	[super dealloc];
}

-(void)reconnect {
	_timeout = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timeout:) userInfo:NULL repeats:NO];
	[super reconnect];
}

-(void)open {
	_timeout = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timeout:) userInfo:NULL repeats:NO];
	[super open];
}

-(void)close {
	if (_timeout) [_timeout invalidate]; _timeout = NULL;
	[super close];
}

-(void)timeout:(NSTimer*)timer {
	_timeout = NULL;
	[self close];
}

-(void)handleData:(NSMutableData*)data {
	if (_executed) return;
	
	CFHTTPMessageRef request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
	CFHTTPMessageAppendBytes(request, (uint8*)[data bytes], [data length]);

	if (!CFHTTPMessageIsHeaderComplete(request))
		return;
	
//	DLog(@"XMLRPC request received: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	NSString* contentLength = (NSString*)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Content-Length");
	if (contentLength) [contentLength autorelease];
	NSData* content = [(NSData*)CFHTTPMessageCopyBody(request) autorelease];
	
	if (contentLength && [content length] < [contentLength intValue])
    {
		CFRelease(request);
        return;
	}
    
	NSString* version = [(NSString*)CFHTTPMessageCopyVersion(request) autorelease];
    if (!version)
    {
        [self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, kCFHTTPVersion1_0)];
        CFRelease(request);
        return;
    }
	
    NSString* method = [(NSString*)CFHTTPMessageCopyRequestMethod(request) autorelease];
    if (!method)
    {
        [self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, (CFStringRef)version)];
        CFRelease(request);
        return;
    }
	
	if (![method isEqualToString:@"POST"])
    {
		[self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, (CFStringRef)version)];
        CFRelease(request);
		return;
	}
	
	_executed = YES;
	[self handleRequest:request];
	
	CFRelease(request);
}

-(void)handleRequest:(CFHTTPMessageRef)request {
	NSString* contentLengthString = (NSString*)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Content-Length");
	if (contentLengthString) [contentLengthString autorelease];
	NSInteger contentLength = contentLengthString? [contentLengthString intValue] : 0;
	NSData* content = [(NSData*)CFHTTPMessageCopyBody(request) autorelease];
	
	if (contentLengthString && contentLength < [content length])
		content = [content subdataWithRange:NSMakeRange(0, contentLength)];
	
	@try {
		NSXMLDocument* doc = [[[NSXMLDocument alloc] initWithData:content options:NSXMLNodeOptionsNone error:NULL] autorelease];

		NSArray* methodCalls = [doc nodesForXPath:@"methodCall" error:NULL];
		if ([methodCalls count] != 1)
			[NSException raise:NSGenericException format:@"request contains %d method calls", [methodCalls count]];
		NSXMLElement* methodCall = [methodCalls objectAtIndex:0];
		
		NSArray* methodNames = [methodCall nodesForXPath:@"methodName" error:NULL];
		if ([methodNames count] != 1)
			[NSException raise:NSGenericException format:@"method call contains %d method names", [methodNames count]];
		NSString* methodName = [[methodNames objectAtIndex:0] stringValue];
		
		DLog(@"Handling XMLRPC method call: %@", methodName);
		
//		NSArray* methodParameterNames = [doc nodesForXPath:@"methodCall/params//member/name" error:NULL];
//		NSMutableArray* methodParameterValues = [[doc nodesForXPath:@"methodCall/params//member/value" error:NULL] mutableArray];
//		if ([methodParameterNames count] != [methodParameterValues count])
//			[NSException raise:NSGenericException format:@"request parameters inconsistent", [methodNames count]];
		NSArray* params = [methodCall nodesForXPath:@"params/param/value/*" error:NULL];
		
//		NSMutableDictionary* methodParameters = [NSMutableDictionary dictionaryWithCapacity:[methodParameterNames count]];
//		for (int i = 0; i < [methodParameterNames count]; ++i)
//			[methodParameters setObject:[[methodParameterValues objectAtIndex:i] objectValue] forKey:[[methodParameterNames objectAtIndex:i] objectValue]];
		
		NSMutableString* methodSignatureString = [NSMutableString stringWithCapacity:128];
		[methodSignatureString appendString:methodName];
		for (NSXMLNode* n in params)
			[methodSignatureString appendString:@":"];
		
		SEL methodSelector = NSSelectorFromString(methodSignatureString);
		if (![_delegate respondsToSelector:methodSelector] || ![_delegate respondsToSelector:@selector(isMethodAvailableToXMLRPC:)] || ![_delegate performSelector:@selector(isMethodAvailableToXMLRPC:) withObject:methodSignatureString])
			[NSException raise:NSGenericException format:@"invalid method/parameters", [methodNames count]];
		
		NSMethodSignature* methodSignature = [_delegate methodSignatureForSelector:methodSelector];
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
		[invocation setTarget:_delegate];
		[invocation setSelector:methodSelector];
		
		//NSLog(@"71210test2 1 %@", [N2Shell hostname]);
		for (int i = 0; i < [params count]; ++i) {
			const char* argType = [methodSignature getArgumentTypeAtIndex:2+i];
			NSXMLNode* n = [params objectAtIndex:i];
			NSObject* o = [N2XMLRPC ParseElement:n];
			
			switch (argType[0]) {
				case '@': {
					[invocation setArgument:&o atIndex:2+i];
				} break;
				case 'i':
				case 'f': {
					NSAssert([o isKindOfClass:[NSNumber class]], @"Expecting a numeric parameter");
					NSNumber* n = (NSNumber*)o;
					switch (argType[0]) {
						case 'i': {
							NSInteger i = [n intValue];
							[invocation setArgument:&i atIndex:2+i];
						} break;
						case 'f': {
							CGFloat f = [n floatValue];
							[invocation setArgument:&f atIndex:2+i];
						} break;
						default: {
							[NSException raise:NSGenericException format:@"client side unsupported argument type %c in %@", argType[0], methodSignature];
						} break;
					}
				} break;
				default: {
					[NSException raise:NSGenericException format:@"client side unsupported argument type %c in %@", argType[0], methodSignature];
				} break;
			}
		}
		
		//NSLog(@"71210test2 8");
		[invocation invoke];

		NSString* returnValue = [N2XMLRPC ReturnElement:invocation];
		NSString* responseXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodResponse><params><param><value>%@</value></param></params></methodResponse>", returnValue];
		NSData* responseData = [responseXml dataUsingEncoding:NSUTF8StringEncoding];
		
		//NSLog(@"71210test2 9");
		CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_0);
		CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [responseData length]]);
		CFHTTPMessageSetBody(response, (CFDataRef)responseData);
		[self writeAndReleaseResponse:response];
	} @catch (NSException* e) {
		NSLog(@"Warning: [N2XMLRPCConnection handleRequest:] %@", [e description]);
		[self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, 500, (CFStringRef)[e description], kCFHTTPVersion1_0)];
	}
}

-(void)writeAndReleaseResponse:(CFHTTPMessageRef)response {
	[self writeData:[(NSData*)CFHTTPMessageCopySerializedMessage(response) autorelease]];
	_waitingToClose = YES;
	CFRelease(response);
}

-(void)lifecycle {
	[super lifecycle];
	if (_waitingToClose && _hasSpaceAvailable)
		[self close];
}

@end
