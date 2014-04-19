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
#import "NSInvocation+N2.h"

#import "N2Shell.h"

@implementation N2XMLRPCConnection

@synthesize delegate = _delegate;
@synthesize dontSpecifyStringType = _dontSpecifyStringType;

-(NSUInteger)N2XMLRPCOptions {
    NSUInteger o = 0;
    if (self.dontSpecifyStringType)
        o |= N2XMLRPCDontSpecifyStringTypeOptionMask;
    return o;
}

-(id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag is:(NSInputStream*)is os:(NSOutputStream*)os {
	if ((self = [super initWithAddress:address port:port tls:tlsFlag is:is os:os])) {
		[self setCloseOnRemoteClose:YES];
	}
	
	return self;
}

-(void)dealloc {
	[self setDelegate:NULL];
    [_doc release];
	[super dealloc];
}

-(void)open {
	@synchronized (self) {
        [_timeout invalidate];
        _timeout = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timeout:) userInfo:NULL repeats:NO];
    }

    [super open];
}

-(void)close {
	@synchronized (self) {
        [_timeout invalidate];
        _timeout = NULL;
    }
    
	[super close];
}

-(void)timeout:(NSTimer*)timer {
	@synchronized (self) {
        _timeout = NULL;
    }

    [self close];
}

-(void)handleData:(NSMutableData*)data {
	if (_executed) return;
	
	CFHTTPMessageRef request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
	CFHTTPMessageAppendBytes(request, (uint8*)[data bytes], [data length]);

	if (!CFHTTPMessageIsHeaderComplete(request))
    {
        CFRelease(request);
		return;
	}
	
	NSString* contentLength = (NSString*)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Content-Length");
	if (contentLength) [contentLength autorelease];
	NSData* content = [(NSData*)CFHTTPMessageCopyBody(request) autorelease];
	
	if (contentLength && [content length] < [contentLength intValue])
    {
		CFRelease(request);
        return;
	}
    
	/*NSString* version = [(NSString*)CFHTTPMessageCopyVersion(request) autorelease];
    if (!version) version = (NSString*)kCFHTTPVersion1_1;
	
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
	}*/
	
	_executed = YES;
	[self handleRequest:request];
	
	CFRelease(request);
}

-(NSString*)selectorStringForXMLRPCRequestMethodName:(NSString*)name isValidated:(BOOL*)isValidated {
    NSString* sel = nil;
    
    if ([_delegate respondsToSelector:@selector(selectorStringForXMLRPCRequestMethodName:)])
        sel = [_delegate selectorStringForXMLRPCRequestMethodName:name];
    if (sel)
        if (isValidated) *isValidated = YES;
    
    if (!sel) {
        sel = [NSString stringWithFormat:@"%@:error:", name];
        if (![_delegate respondsToSelector:NSSelectorFromString(sel)])
            sel = [NSString stringWithFormat:@"%@:", name];
        if (isValidated) *isValidated = NO;
    }
    
    return sel;
}

-(void)handleRequest:(CFHTTPMessageRef)request {
	NSString* contentLengthString = (NSString*)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Content-Length");
	if (contentLengthString) [contentLengthString autorelease];
	NSInteger contentLength = contentLengthString? [contentLengthString intValue] : 0;
	NSData* content = [(NSData*)CFHTTPMessageCopyBody(request) autorelease];
    
    NSString* version = [(id)CFHTTPMessageCopyVersion(request) autorelease];
    if (!version) version = (NSString*)kCFHTTPVersion1_1;
	
	if (contentLengthString && contentLength < [content length])
		content = [content subdataWithRange:NSMakeRange(0, contentLength)];
	
	@try {
        if (_doc) [_doc release];
        NSError *error = nil;
		_doc = [[NSXMLDocument alloc] initWithData:content options:NSXMLNodeOptionsNone error: &error];
        if (!_doc)
        {
            if( content.length)
                NSLog( @"--- incomplete/corrupted XML document: %@", error.localizedDescription);
            return; // data is incomplete, try later with more data
        }
//        DLog(@"Handling XMLRPC request: %@", [doc XMLString]);
        
		NSArray* methodCalls = [_doc nodesForXPath:@"methodCall" error:NULL];
		if ([methodCalls count] != 1)
			[NSException raise:NSGenericException format:@"request contains %d method calls", (int) [methodCalls count]];
		NSXMLElement* methodCall = [methodCalls objectAtIndex:0];
        
        [_inputStream close]; [_inputStream release]; _inputStream = nil;
        
       // [self performSelectorInBackground:@selector(handleXmlrpcMethodCall:) withObject:[NSArray arrayWithObjects: methodCall, version, nil]]; // naaah we're already in a dedicated thread
        [self performSelector:@selector(handleXmlrpcMethodCall:) withObject:[NSArray arrayWithObjects: methodCall, version, nil]];
	} @catch (NSException* e) {
		NSLog(@"Warning: [N2XMLRPCConnection handleRequest:] %@", [e reason]);
		[self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, 500, (CFStringRef)[e reason], (CFStringRef)version)];
	}
}

-(void)handleXmlrpcMethodCall:(NSArray*)args {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSString* version = [args objectAtIndex:1];
    
    @try {
        NSXMLElement* methodCall = [args objectAtIndex:0];
        
        NSArray* methodNames = [methodCall nodesForXPath:@"methodName" error:NULL];
        if ([methodNames count] != 1)
            [NSException raise:NSGenericException format:@"method call contains %d method names", (int) [methodNames count]];
        NSString* methodName = [[methodNames objectAtIndex:0] stringValue];
        
        DLog(@"XMLRPC call: %@", methodName);
        
        //		NSArray* methodParameterNames = [doc nodesForXPath:@"methodCall/params//member/name" error:NULL];
        //		NSMutableArray* methodParameterValues = [[doc nodesForXPath:@"methodCall/params//member/value" error:NULL] mutableArray];
        //		if ([methodParameterNames count] != [methodParameterValues count])
        //			[NSException raise:NSGenericException format:@"request parameters inconsistent", [methodNames count]];
        NSArray* params = [methodCall nodesForXPath:@"params/param/value" error:NULL];
        
        //		NSMutableDictionary* methodParameters = [NSMutableDictionary dictionaryWithCapacity:[methodParameterNames count]];
        //		for (int i = 0; i < [methodParameterNames count]; ++i)
        //			[methodParameters setObject:[[methodParameterValues objectAtIndex:i] objectValue] forKey:[[methodParameterNames objectAtIndex:i] objectValue]];
        
        NSMutableArray* objcparams = [NSMutableArray array];
        for (NSXMLNode* param in params)
            [objcparams addObject:[N2XMLRPC ParseElement:param]];
        
        NSError* error = nil;
        
        NSDate* dateBeforeCall = [NSDate date];
        NSObject* result = [self methodCall:methodName params:objcparams error:&error];
        
        if (error) {
            NSLog(@"Warning: [N2XMLRPCConnection handleRequest:] %@", [error localizedDescription]);
            [self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, error.code, (CFStringRef)error.localizedDescription, (CFStringRef)version)];
            return;
        }
        
        DLog(@"\tXMLRPC done, took %f seconds.", -[dateBeforeCall timeIntervalSinceNow]);
        
        NSData* responseData = [[N2XMLRPC responseWithValue:result options:[self N2XMLRPCOptions]] dataUsingEncoding:NSUTF8StringEncoding];
        
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, (CFStringRef)version);
        CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", (int) [responseData length]]);
        CFHTTPMessageSetBody(response, (CFDataRef)responseData);
        [self writeAndReleaseResponse:response];
    } @catch (NSException* e) {
		NSLog(@"Warning: [N2XMLRPCConnection handleRequest:] %@", [e reason]);
		[self writeAndReleaseResponse:CFHTTPMessageCreateResponse(kCFAllocatorDefault, 500, (CFStringRef)[e reason], (CFStringRef)version)];
	} @finally {
        [pool release];
    }
}

-(id)methodCall:(NSString*)methodName params:(NSArray*)params error:(NSError**)error {
    BOOL methodSelectorIsValidated = NO;
    NSString* methodSelectorString = [self selectorStringForXMLRPCRequestMethodName:methodName isValidated:&methodSelectorIsValidated];
    SEL methodSelector = NSSelectorFromString(methodSelectorString);
    if (!methodSelectorIsValidated && (![_delegate respondsToSelector:methodSelector] || ([_delegate respondsToSelector:@selector(isMethodAvailableToXMLRPC:)] && ![_delegate isSelectorAvailableToXMLRPC:methodSelectorString])))
        [NSException raise:NSGenericException format:@"invalid XMLRPC method call: %@", methodName];

    //		DLog(@"\tHandled by: %@", methodSelectorString);
    
    NSInvocation* invocation = [NSInvocation invocationWithSelector:methodSelector target:_delegate];
   
    if (params.count < 1)
        params = [NSArray arrayWithObject:[NSDictionary dictionary]];

    int paramIndex = 0;
    for (; paramIndex < [params count]; ++paramIndex)
        [invocation setArgumentObject:[params objectAtIndex:paramIndex] atIndex:paramIndex+2];
    
    if ([methodSelectorString hasSuffix:@":error:"]) {
        [invocation setArgument:&error atIndex:2+paramIndex];
    }
    
    [invocation invoke];
    
    return [invocation returnValue];
}

-(void)writeAndReleaseResponse:(CFHTTPMessageRef)response {
    self.closeWhenDoneSending = YES;
	[self writeData:[(NSData*)CFHTTPMessageCopySerializedMessage(response) autorelease]];
	_waitingToClose = YES;
	CFRelease(response);
}

-(void)connectionFinishedSendingData {
	if (_waitingToClose)
		[self close];
}

@end
