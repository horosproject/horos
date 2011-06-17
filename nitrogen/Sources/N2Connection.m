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

#undef DEBUG

#import "N2Connection.h"
#import "N2Debug.h"
#import "NSThread+N2.h"
//#include <math.h>
//#include <algorithm>
//#include <iostream>

@interface N2Connection ()

-(void)open;

@end

@interface N2ConnectionWithDelegateHandler : N2Connection {
	NSInvocation* _invocation;
}

@property(readonly) NSInvocation* invocation;

-(id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context;

@end


NSString* const N2ConnectionStatusDidChangeNotification = @"N2ConnectionStatusDidChangeNotification";

@implementation N2Connection
@synthesize address = _address, status = _status, maximumReadSizePerEvent = _maximumReadSizePerEvent;

+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port {
	return [self sendSynchronousRequest:request toAddress:address port:port tls:NO];
}

+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag {
	NSConditionLock* conditionLock = [[NSConditionLock alloc] initWithCondition:0]; 
	NSMutableArray* io = [NSMutableArray arrayWithObjects: conditionLock, [NSThread currentThread], request, address, [NSNumber numberWithInteger:port], [NSNumber numberWithBool:tlsFlag], nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendSynchronousRequestThread:) object:io];
	[thread start];
	[conditionLock lockWhenCondition:1];
	[conditionLock unlock];
	[conditionLock release];
	[thread release];
	
	id response = io.count? [io lastObject] : nil;
	if ([response isKindOfClass:NSException.class])
		@throw response;
	return response;
} 

+(void)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context {
	[self sendSynchronousRequest:request toAddress:address port:port tls:NO dataHandlerTarget:target selector:selector context:context];
}

+(void)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context  {
	if (!request) request = [NSData data];
	
	NSConditionLock* conditionLock = [[NSConditionLock alloc] initWithCondition:0]; 
	NSMutableArray* io = [NSMutableArray arrayWithObjects: conditionLock, [NSThread currentThread], request, address, [NSNumber numberWithInteger:port], [NSNumber numberWithBool:tlsFlag], target, [NSValue valueWithPointer:selector], [NSValue valueWithPointer:context], nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendSynchronousRequestThread:) object:io];
	[thread start];
	[conditionLock lockWhenCondition:1];
	
//	if (io.count == 9) {
//		NSInvocation* invocation = [io objectAtIndex:7];
//		[invocation invoke];
//		[conditionLock unlockWithCondition:0];
//	}
	
	[conditionLock unlock];
	[conditionLock release];
	[thread release];
	
	if (io.count) {
		id lo = [io lastObject];
		if ([lo isKindOfClass:NSException.class])
			@throw lo;
	}
}

+(void)sendSynchronousRequestThread:(NSMutableArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSConditionLock* conditionLock = [io objectAtIndex:0];
	NSThread* motherThread = [io objectAtIndex:1];
	
	N2Connection* c = nil;
	@try {
		NSData* request = [io objectAtIndex:2]; 
		NSString* address = [io objectAtIndex:3];
		NSInteger port = [[io objectAtIndex:4] integerValue];
		BOOL tlsFlag = [[io objectAtIndex:5] boolValue];
		
		if (io.count == 9) {
			id dataHandlerTarget = [io objectAtIndex:6];
			SEL dataHandlerSelector = (SEL)[[io objectAtIndex:7] pointerValue];
			void* dataHandlerContext = [[io objectAtIndex:8] pointerValue];
			c = [[N2ConnectionWithDelegateHandler alloc] initWithAddress:address port:port tls:tlsFlag dataHandlerTarget:dataHandlerTarget selector:dataHandlerSelector context:dataHandlerContext];
//			[io addObject:((N2ConnectionWithDelegateHandler*)c).invocation];
		} else {
			c = [[N2Connection alloc] initWithAddress:address port:port tls:tlsFlag];
		}
		
		c.maximumReadSizePerEvent = 1024*32;
		if (request.length) [c writeData:request];
		
		while (c.status != N2ConnectionStatusClosed && !motherThread.isCancelled) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
		}
		
		[io removeAllObjects];
		[io addObject:[c readData:0]];
		
	} @catch (NSException* e) {
		[io addObject:e];
	} @finally {
		[c release];
		[pool release];
		[conditionLock lockWhenCondition:0];
		[conditionLock unlockWithCondition:1];
	}
}

-(id)initWithAddress:(NSString*)address port:(NSInteger)port {
	return [self initWithAddress:address port:port is:nil os:nil];
}

-(id)initWithAddress:(NSString*)address port:(NSInteger)port is:(NSInputStream*)is os:(NSOutputStream*)os {
	return [self initWithAddress:address port:port tls:NO is:is os:os];
}

-(id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag {
	return [self initWithAddress:address port:port tls:tlsFlag is:nil os:nil];
}

-(id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag is:(NSInputStream*)is os:(NSOutputStream*)os {
	self = [super init];
	
	_address = [address retain];
	_port = port;
	_tlsFlag = tlsFlag;
	
	_inputBuffer = [[NSMutableData alloc] initWithCapacity:1024];
	_outputBuffer = [[NSMutableData alloc] initWithCapacity:1024];
	
	if (is && os) {
		_inputStream = [is retain];
		_outputStream = [os retain];
		[self open];
	} else
		[self reconnect];
	
	return self;
}


-(void)reconnectToAddress:(NSString*)address port:(NSInteger)port {
	[_address release];
	_address = [address retain];
	_port = port;
	[self reconnect];
}

-(void)dealloc {
//	NSLog(@"[N2Connection dealloc]");
	[self close];
	[_inputBuffer release];
	[_outputBuffer release];
	[_address release];
	[super dealloc];
}

-(void)reconnect {
	[self close];
	
	[_inputBuffer setLength:0];
	[_outputBuffer setLength:0];
	
	[self setStatus:N2ConnectionStatusConnecting];
	[NSStream getStreamsToHost:[NSHost hostWithName:_address] port:_port inputStream:&_inputStream outputStream:&_outputStream];
	[_inputStream retain]; [_outputStream retain];
	
	[self open];
}

-(void)startTLS {
	_tlsFlag = YES;
	NSMutableDictionary* settings = [NSMutableDictionary dictionary];
	[settings setObject:NSStreamSocketSecurityLevelNegotiatedSSL forKey:(NSString*)kCFStreamSSLLevel];
	[settings setObject:_address forKey:(NSString*)kCFStreamSSLPeerName];
	[_inputStream setProperty:settings forKey:(NSString*)kCFStreamPropertySSLSettings];
	[_outputStream setProperty:settings forKey:(NSString*)kCFStreamPropertySSLSettings];
	[_inputStream open];
	[_outputStream open];
}

-(void)open {
	if (self.status == N2ConnectionStatusConnecting) {
		[self setStatus:N2ConnectionStatusOpening];
		[_inputStream setDelegate:self];
		[_outputStream setDelegate:self];
		[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	}
	
	if (_tlsFlag)
		[self startTLS];
	else {
		[_inputStream open];
		[_outputStream open];
	}
}

-(BOOL)isSecure {
	return _tlsFlag;
}

-(void)setStatus:(N2ConnectionStatus)status {
	if (status == _status)
		return;
	
	// NSString* N2ConnectionStatusName[] = {@"N2ConnectionStatusClosed", @"N2ConnectionStatusConnecting", @"N2ConnectionStatusOpening", @"N2ConnectionStatusOk"};
	// DLog(@"%@ setting status: %@", self, N2ConnectionStatusName[status]);
	
	_status = status;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:N2ConnectionStatusDidChangeNotification object:self];
}

-(void)close {
	if ([self status] == N2ConnectionStatusClosed)
		return;
	[self setStatus:N2ConnectionStatusClosed];
//	NSLog(@"Close %d", self.retainCount);
	
	if (_outputStream)
		[_outputStream close];
	[_outputStream release]; _outputStream = NULL;
	
	if (_inputStream)
		[_inputStream close];
	[_inputStream release]; _inputStream = NULL;
	
	_handleOpenCompleted = 0;
}

#pragma deprecated (invalidate)
-(void)invalidate {
	[self close];
}

-(void)handleData:(NSMutableData*)data {
//	[data setLength:0];
}

-(void)trySendingDataNow {
	NSUInteger length = [_outputBuffer length];
	if (length) {
		NSUInteger sentLength = [_outputStream write:(uint8_t*)[_outputBuffer bytes] maxLength:length];
		if (sentLength != -1) {
//			NSLog(@"%@ Sent %d bytes (of %d)", self, sentLength, length);
			[_outputBuffer replaceBytesInRange:NSMakeRange(0,sentLength) withBytes:nil length:0];
			if (!_outputBuffer.length) {
//				NSLog(@"All data sent");
				[self connectionFinishedSendingData];
			}
		} else
			DLog(@"%@ Send error: %@", self, [_outputStream streamError]);
	}
}

-(void)connectionFinishedSendingData {
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {
//#ifdef DEBUG
//	NSString* NSEventName[] = {@"NSStreamEventNone", @"NSStreamEventOpenCompleted", @"NSStreamEventHasBytesAvailable", @"NSStreamEventHasSpaceAvailable", @"NSStreamEventErrorOccurred", @"NSStreamEventEndEncountered"};
//	NSLog(@"%@ stream:%@ handleEvent:%@", self, stream, NSEventName[(int)log2(event)+1]);
//#endif
	
	if (event == NSStreamEventOpenCompleted)
		if (++_handleOpenCompleted == 2) {
			[self setStatus:N2ConnectionStatusOk];
//			[self trySendingDataNow];
		}
	
	if (stream == _inputStream && event == NSStreamEventHasBytesAvailable) {
		// DLog(@"%@ has bytes available", self);
		NSUInteger readSizeForThisEvent = 0;
		while (!_maximumReadSizePerEvent || readSizeForThisEvent < _maximumReadSizePerEvent) {
			NSUInteger maxLength = 2048;
			if (_maximumReadSizePerEvent && maxLength > _maximumReadSizePerEvent-readSizeForThisEvent)
				maxLength = _maximumReadSizePerEvent-readSizeForThisEvent;
			uint8_t buffer[maxLength];
			unsigned int length = [_inputStream read:buffer maxLength:maxLength];
			
			if (length > 0) {
				// DLog(@"%@ Read %d Bytes", self, length);
//				std::cerr << [[NSString stringWithFormat:@"%@ Read %d Bytes", self, length] UTF8String] << ": ";
//				for (int i = 0; i < length; ++i)
//					std::cerr << (int)buffer[i] << " ";
//				std::cerr << std::endl;
				readSizeForThisEvent += length;
				[_inputBuffer appendBytes:buffer length:length];
			} else
				break;
			
			[self handleData:_inputBuffer];
		}
		
		if (readSizeForThisEvent == _maximumReadSizePerEvent)
			[self performSelector:@selector(streamHandleEvent:) withObject:[NSArray arrayWithObjects:stream, [NSNumber numberWithUnsignedInteger:event], nil] afterDelay:0];
	}
	
	if (stream == _outputStream && event == NSStreamEventHasSpaceAvailable && [_outputBuffer length])
		[self performSelector:@selector(trySendingDataNow) withObject:nil afterDelay:0];
	
	if (event == NSStreamEventEndEncountered)
		[stream close];
	
	if (event == NSStreamEventErrorOccurred) {
		NSLog(@"Stream error: %@ %@", stream.streamError, stream.streamError.userInfo);
		[self close];
	}
}

-(void)streamHandleEvent:(NSArray*)io {
	[self stream:[io objectAtIndex:0] handleEvent:[[io objectAtIndex:1] unsignedIntegerValue]];
}

-(void)writeData:(NSData*)data {
	[_outputBuffer appendData:data];
	if (self.status == N2ConnectionStatusOk)	
		[self trySendingDataNow];
	// the output buffer is sent every 0.01 seconds - that's quick enough, otherwise [self transferData:NULL];
}

-(NSInteger)availableSize {
	return [_inputBuffer length];
}

-(NSData*)readData:(NSInteger)size {
	NSInteger availableSize = [_inputBuffer length];
	
	NSRange range = NSMakeRange(0, size? MIN(size, availableSize) : availableSize);
	NSData* data = [_inputBuffer subdataWithRange:range];
	[_inputBuffer replaceBytesInRange:range withBytes:nil length:0];
	
	return data;
}

-(NSInteger)readData:(NSInteger)size toBuffer:(void*)buffer {
	NSInteger availableSize = [_inputBuffer length];
	
	NSRange range = NSMakeRange(0, size? MIN(size, availableSize) : availableSize);
	[_inputBuffer getBytes:buffer range:range];
	[_inputBuffer replaceBytesInRange:range withBytes:nil length:0];
	
	return range.length;
}


/*
-(NSString*)host2ipv6:(NSString*)host {
	
}

+(BOOL)host:(NSString*)host1 isEqualToHost:(NSString*)host2 {
	return [[self host2ipv6:host1] isEqual:[self host2ipv6:host2]];
}
*/

@end


@implementation N2ConnectionWithDelegateHandler

@synthesize invocation = _invocation;

-(id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context {
	if ((self = [super initWithAddress:address port:port tls:tlsFlag])) {
		_invocation = [[NSInvocation invocationWithMethodSignature:[N2ConnectionWithDelegateHandler instanceMethodSignatureForSelector:@selector(_connection:dummyDataHandler:context:)]] retain];
		[_invocation setSelector:selector];
		[_invocation setTarget:target];
		[_invocation setArgument:&self atIndex:2];
		[_invocation setArgument:&context atIndex:4];
	}
	
	return self;
}

-(NSInteger)_connection:(N2Connection*)connection dummyDataHandler:(NSData*)data context:(void*)context {
	return 0;
}

-(void)dealloc {
	[_invocation release];
	[super dealloc];
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {
	[super stream:stream handleEvent:event];
	
	if (event == NSStreamEventEndEncountered) {
		id null = nil;
		[_invocation setArgument:&null atIndex:3];
		[_invocation invoke];
	}

}

-(void)handleData:(NSMutableData*)data {
	[_invocation setArgument:&data atIndex:3];
	[_invocation invoke];
	NSInteger handledDataSize;
	[_invocation getReturnValue:&handledDataSize];
	[data replaceBytesInRange:NSMakeRange(0, handledDataSize) withBytes:nil length:0];
}

@end



