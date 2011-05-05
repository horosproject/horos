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
#include <math.h>
#include <algorithm>
#include <iostream>

@interface N2Connection ()

-(void)open;

@end

@interface N2ConnectionWithDelegateHandler : N2Connection {
	NSInvocation* _invocation;
}

@property(readonly) NSInvocation* invocation;

-(id)initWithAddress:(NSString*)address port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context;

@end


const NSString* N2ConnectionStatusDidChangeNotification = @"N2ConnectionStatusDidChangeNotification";

@implementation N2Connection
@synthesize address = _address, status = _status, maximumReadSizePerEvent = _maximumReadSizePerEvent;

+(NSData*)sendSynchronousRequest:(NSData*)request toHost:(NSHost*)host port:(NSInteger)port {
	NSConditionLock* conditionLock = [[NSConditionLock alloc] initWithCondition:0]; 
	NSMutableArray* io = [NSMutableArray arrayWithObjects: conditionLock, [NSThread currentThread], request, host, [NSNumber numberWithInteger:port], nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendSynchronousRequestThread:) object:io];
	[thread start];
	[conditionLock lockWhenCondition:1];
	[conditionLock unlock];
	[conditionLock release];
	[thread release];
	
	NSData* response = io.count? [io lastObject] : nil;
	return response;
} 

+(void)sendSynchronousRequest:(NSData*)request toHost:(NSHost*)host port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context {
	NSConditionLock* conditionLock = [[NSConditionLock alloc] initWithCondition:0]; 
	NSMutableArray* io = [NSMutableArray arrayWithObjects: conditionLock, [NSThread currentThread], request, host, [NSNumber numberWithInteger:port], target, [NSValue valueWithPointer:selector], [NSValue valueWithPointer:context], nil];
	
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
}

+(void)sendSynchronousRequestThread:(NSMutableArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSConditionLock* conditionLock = [io objectAtIndex:0];
	NSThread* motherThread = [io objectAtIndex:1];

	@try {
		NSData* request = [io objectAtIndex:2]; 
		NSHost* host = [io objectAtIndex:3];
		NSInteger port = [[io objectAtIndex:4] integerValue];
		
		N2Connection* c;
		if (io.count == 8) {
			id dataHandlerTarget = [io objectAtIndex:5];
			SEL dataHandlerSelector = (SEL)[[io objectAtIndex:6] pointerValue];
			void* dataHandlerContext = [[io objectAtIndex:7] pointerValue];
			c = [[N2ConnectionWithDelegateHandler alloc] initWithAddress:host.address port:port dataHandlerTarget:dataHandlerTarget selector:dataHandlerSelector context:dataHandlerContext];
//			[io addObject:((N2ConnectionWithDelegateHandler*)c).invocation];
		} else {
			c = [[N2Connection alloc] initWithAddress:host.address port:port];
		}
		
		c.maximumReadSizePerEvent = 1024*32;
		[c writeData:request];
		
		while (c.status != N2ConnectionStatusClosed && !motherThread.isCancelled) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
		}
		
		[io removeAllObjects];
		[io addObject:[c readData:0]];
		
		[c release];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
		[conditionLock lockWhenCondition:0];
		[conditionLock unlockWithCondition:1];
	}
}

-(id)initWithAddress:(NSString*)address port:(NSInteger)port {
	return [self initWithAddress:address port:port is:nil os:nil];
}


-(id)initWithAddress:(NSString*)address port:(NSInteger)port is:(NSInputStream*)is os:(NSOutputStream*)os {
	self = [super init];
	
	_address = [address retain];
	_port = port;
	
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
	DLog(@"[N2Connection dealloc]");
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

-(void)open {
	[self setStatus:N2ConnectionStatusOpening];
	[_inputStream setDelegate:self];
	[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream open];
	[_outputStream setDelegate:self];
	[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream open];
}

-(void)setStatus:(N2ConnectionStatus)status {
	if (status == _status)
		return;
	
	NSString* N2ConnectionStatusName[] = {@"N2ConnectionStatusClosed", @"N2ConnectionStatusConnecting", @"N2ConnectionStatusOpening", @"N2ConnectionStatusOk"};
	// DLog(@"%@ setting status: %@", self, N2ConnectionStatusName[status]);
	
	_status = status;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:N2ConnectionStatusDidChangeNotification object:self];
}

-(void)close {
	if ([self status] == N2ConnectionStatusClosed)
		return;
	[self setStatus:N2ConnectionStatusClosed];
	
	if (_outputStream) {
		[_outputStream close];
		[_outputStream release]; _outputStream = NULL;
	}
	
	if (_inputStream) {
		[_inputStream close];
		[_inputStream release]; _inputStream = NULL;
	}
	
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
			// DLog(@"%@ Sent %d bytes", self, sentLength);
			[_outputBuffer replaceBytesInRange:NSMakeRange(0,sentLength) withBytes:nil length:0];
			if (!_outputBuffer.length)
				[self connectionFinishedSendingData];
		} else
			DLog(@"%@ send error: %@", self, [_outputStream streamError]);
	}
}

-(void)connectionFinishedSendingData {
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {
#ifdef DEBUG
	NSString* NSEventName[] = {@"NSStreamEventNone", @"NSStreamEventOpenCompleted", @"NSStreamEventHasBytesAvailable", @"NSStreamEventHasSpaceAvailable", @"NSStreamEventErrorOccurred", @"NSStreamEventEndEncountered"};
	//NSLog(@"%@ stream:%@ handleEvent:%@", self, stream, NSEventName[(int)log2(event)+1]);
#endif
	
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
	
	if (event == NSStreamEventErrorOccurred || event == NSStreamEventEndEncountered)
		[self close];
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

-(id)initWithAddress:(NSString*)address port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context {
	if ((self = [super initWithAddress:address port:port])) {
		_invocation = [[NSInvocation invocationWithMethodSignature:[N2ConnectionWithDelegateHandler instanceMethodSignatureForSelector:@selector(dummyDataHandler:context:)]] retain];
		[_invocation setSelector:selector];
		[_invocation setTarget:target];
		[_invocation setArgument:&context atIndex:3];
	}
	
	return self;
}

-(NSInteger)dummyDataHandler:(NSData*)data context:(void*)context {
	return 0;
}

-(void)dealloc {
	[_invocation release];
	[super dealloc];
}

-(void)handleData:(NSMutableData*)data {
	[_invocation setArgument:&data atIndex:2];
	[_invocation invoke];
	NSInteger handledDataSize;
	[_invocation getReturnValue:&handledDataSize];
	[data replaceBytesInRange:NSMakeRange(0, handledDataSize) withBytes:nil length:0];
}

@end



