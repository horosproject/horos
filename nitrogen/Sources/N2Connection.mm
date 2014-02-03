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
#import "NSException+N2.h"
#import "NSHost+N2.h"
#include <math.h>
#include <algorithm>
#include <iostream>

@interface N2Connection ()

@property(readwrite,retain) NSError* error;

-(void)open;

@end

@interface N2ConnectionWithDelegateHandler : N2Connection {
	NSInvocation* _invocation;
}

@property(readonly) NSInvocation* invocation;

-(id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context;

@end


NSString* N2ConnectionStatusDidChangeNotification = @"N2ConnectionStatusDidChangeNotification";

@implementation N2Connection

@synthesize status = _status;
@synthesize maximumReadSizePerEvent = _maximumReadSizePerEvent;
@synthesize closeOnRemoteClose = _closeOnRemoteClose;
@synthesize error = _error;
@synthesize closeWhenDoneSending = _closeWhenDoneSending;
@synthesize closeOnNextSpaceAvailable = _closeOnNextSpaceAvailable;
@synthesize lastEventTimeInterval;

+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port {
	return [self sendSynchronousRequest:request toAddress:address port:port tls:NO];
}

+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag {
	return [self sendSynchronousRequest:request toAddress:address port:port tls:tlsFlag dataHandlerTarget:nil selector:nil context:nil];
} 

+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context {
	return [self sendSynchronousRequest:request toAddress:address port:port tls:NO dataHandlerTarget:target selector:selector context:context];
}

+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context  {
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
    
    id response = io.count? [io lastObject] : nil;
	if ([response isKindOfClass:[NSException class]])
		@throw response;
	return response;
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
		
        c.closeOnRemoteClose = YES;
		c.maximumReadSizePerEvent = 1024*128;
		if (request.length) [c writeData:request];
		
        #define TIMEOUT 45
        NSTimeInterval lastTimeInterval = [NSDate timeIntervalSinceReferenceDate] + 1;
        
		while (c.status != N2ConnectionStatusClosed && !motherThread.isCancelled)
        {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow: 1]];
            
            if( lastTimeInterval < [NSDate timeIntervalSinceReferenceDate])
            {
                lastTimeInterval = [NSDate timeIntervalSinceReferenceDate] + 1;
                
                if( (int) ([NSDate timeIntervalSinceReferenceDate] - c.lastEventTimeInterval) > 1 && c.lastEventTimeInterval > 0)
                    NSLog( @"****** N2Connection stalled: %d", (int) ([NSDate timeIntervalSinceReferenceDate] - c.lastEventTimeInterval));
                
                if( [NSDate timeIntervalSinceReferenceDate] - c.lastEventTimeInterval > TIMEOUT)
                {
                    N2LogStackTrace( @"N2Connection timeout.");
                    c.error = [NSError errorWithDomain:N2ErrorDomain code:-31 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"N2Connection timeout.", NULL), NSLocalizedDescriptionKey, NULL]];
                    break;
                }
            }
		}
		
		[io removeAllObjects];
		[io addObject:[c readData:0]];
        
        if (c.error)
            [NSException raise:NSGenericException format:@"%@", [c.error localizedDescription]];
        
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
	if ((self = [super init])) {
        _address = [address retain];
        _port = port;
        _tlsFlag = tlsFlag;
        
        _inputBuffer = [[NSMutableData alloc] initWithCapacity:1024*128];
        _outputBuffer = [[NSMutableData alloc] initWithCapacity:1024*128];
        
        if (is && os) {
            _status = N2ConnectionStatusConnecting;
            _inputStream = [is retain];
            _outputStream = [os retain];
            [self open];
        } else
            [self reconnect];
    }
	
	return self;
}

-(NSString*)address {
    if ([_address isKindOfClass:[NSString class]])
        return _address;
    return [(NSHost*)_address address];
}

-(void)reconnectToAddress:(id)address port:(NSInteger)port {
	[_address release];
	_address = [address retain];
	_port = port;
	[self reconnect];
}

-(void)dealloc {
    //  NSLog(@"[N2Connection dealloc]");   
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
    _outputBufferIndex = 0;
	
    NSHost* host = [_address isKindOfClass:[NSHost class]]? _address : [NSHost hostWithAddressOrName:_address];
    
	[self setStatus:N2ConnectionStatusConnecting];
    
	[NSStream getStreamsToHost:host port:_port inputStream:&_inputStream outputStream:&_outputStream];
	[_inputStream retain]; [_outputStream retain];
	
	[self open];
}

-(void)startTLS {
	_tlsFlag = YES;
	NSMutableDictionary* settings = [NSMutableDictionary dictionary];
	[settings setObject:NSStreamSocketSecurityLevelNegotiatedSSL forKey:(NSString*)kCFStreamSSLLevel];
	[settings setObject:self.address forKey:(NSString*)kCFStreamSSLPeerName];
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

-(void)setStatus:(NSInteger)status {
	if (status == _status)
		return;
	
//	NSString* N2ConnectionStatusName[] = {@"N2ConnectionStatusClosed", @"N2ConnectionStatusConnecting", @"N2ConnectionStatusOpening", @"N2ConnectionStatusOk"};
//	DLog(@"%@ setting status: %@", self, N2ConnectionStatusName[status]);
	
	_status = status;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:N2ConnectionStatusDidChangeNotification object:self];
}

-(void)close {
	if ([self status] == N2ConnectionStatusClosed)
		return;
	[self setStatus:N2ConnectionStatusClosed];
    
	if (_outputStream)
		[_outputStream close];
	[_outputStream release]; _outputStream = nil;
	
	if (_inputStream)
		[_inputStream close];
	[_inputStream release]; _inputStream = nil;
	
	_handleOpenCompleted = 0;
    
    [[self class] cancelPreviousPerformRequestsWithTarget: self];
}

#pragma deprecated (invalidate)
-(void)invalidate {
	[self close];
}

-(void)handleData:(NSMutableData*)data {
	//	[data setLength:0];
}

-(void)trySendingDataNow {
	NSUInteger length = [_outputBuffer length] - _outputBufferIndex;
	if (length && _handleHasSpaceAvailable && _outputStream.streamStatus == NSStreamStatusOpen) {
		NSUInteger sentLength = [_outputStream write:(uint8_t*)[_outputBuffer bytes]+_outputBufferIndex maxLength:length];
		if (sentLength != -1) {
			if (sentLength < length)
                --_handleHasSpaceAvailable;
//          DLog(@"%@ Sent %d bytes (of %d)", self, (int)sentLength, (%d)length);
            //[_outputBuffer replaceBytesInRange:NSMakeRange(0,sentLength) withBytes:nil length:0];
            _outputBufferIndex += sentLength;
			if (_outputBufferIndex == [_outputBuffer length]) { // output buffer is empty
                [_outputBuffer setLength:0];
                _outputBufferIndex = 0;
                //				NSLog(@"All data sent");
                if (self.closeWhenDoneSending)
                    self.closeOnNextSpaceAvailable = YES;
				[self connectionFinishedSendingData];
			}
		} else
			NSLog(@"%@ Send error: %@", self, [_outputStream streamError]);
	}
}

-(void)connectionFinishedSendingData {
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {
	//#ifdef DEBUG
//	NSString* NSEventName[] = {@"NSStreamEventNone", @"NSStreamEventOpenCompleted", @"NSStreamEventHasBytesAvailable", @"NSStreamEventHasSpaceAvailable", @"NSStreamEventErrorOccurred", @"NSStreamEventEndEncountered"};
//	NSLog(@"%@ stream:%@ handleEvent:%@", self, stream, NSEventName[(int)log2(event)+1]);
	//#endif
	
    lastEventTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    
    switch (event) {
            
        case NSStreamEventOpenCompleted: {
            if (++_handleOpenCompleted == 2)
                [self setStatus:N2ConnectionStatusOk];
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            // DLog(@"%@ has bytes available", self);
            NSUInteger maxLength = _maximumReadSizePerEvent? _maximumReadSizePerEvent : 8192; // was 2048 but bigger buffer = less iterations
            uint8_t buffer[maxLength];
            NSInteger length;
            do {
                if ((length = [_inputStream read:buffer maxLength:maxLength]) > 0) {
                    // DLog(@"%@ Read %d Bytes", self, (int)length);
//                  std::cerr << [[NSString stringWithFormat:@"%@ Read %d Bytes", self, length] UTF8String] << ": ";
//                     for (int i = 0; i < length; ++i)
//                      std::cerr << (int)buffer[i] << " ";
//                  std::cerr << std::endl;
//                  readSizeForThisEvent += length;
                    [_inputBuffer appendBytes:buffer length:length];
                    if (!_handlingData) {
                        _handlingData = YES;
                        @try {
                            [self handleData:_inputBuffer];
                        } @catch (NSException* e) {
                            N2LogExceptionWithStackTrace(e);
                        } @finally {
                            _handlingData = NO;
                        }
                    }
                    
                    if (length < maxLength)
                        break;
                } else {
                    if (length < 0) {
                        [NSException raise:NSGenericException format:@"%@", @"Warning: [NSInputStream read:maxLength:]"];
//                        [self performSelector:@selector(close) withObject:nil afterDelay:0];
                    }
                }
            } while (length > 0);
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            ++_handleHasSpaceAvailable;
            if (self.closeOnNextSpaceAvailable)
                [self performSelector:@selector(close) withObject:nil afterDelay:0];
            else {
                if ([_outputBuffer length] > _outputBufferIndex)
                    [self performSelector:@selector(trySendingDataNow) withObject:nil afterDelay:0];
            }
        } break;
            
        case NSStreamEventEndEncountered: {
            [stream close];
            if ([self closeOnRemoteClose])
                [self performSelector:@selector(close) withObject:nil afterDelay:0];
        } break;
            
        case NSStreamEventErrorOccurred: {
            self.error = stream.streamError;
            NSLog(@"Stream error: %@ %@", self.error, self.error.userInfo);
            [self performSelector:@selector(close) withObject:nil afterDelay:0];
        } break;
            
        default: {
            NSLog(@"Warning: unhandled N2Connection event %d", (int)event);
        } break;
    }
}

-(void)writeData:(NSData*)data {
  //  NSLog(@"writeData: appending %d bytes to %d bytes | status %d", data.length, _outputBuffer.length, self.status);
    if (_outputBufferIndex == _outputBuffer.length) { // all data was sent, reset the send buffer
        [_outputBuffer setLength:0];
        _outputBufferIndex = 0;
    } else if (_outputBufferIndex > 1024*1024) { // more than 1 MB of data was sent, reduce the buffer
        [_outputBuffer replaceBytesInRange:NSMakeRange(0, _outputBufferIndex) withBytes:nil length:0];
        _outputBufferIndex = 0;
    }
    
	[_outputBuffer appendData:data];
	
    if (self.status == N2ConnectionStatusOk)
		[self trySendingDataNow];
   // NSLog(@"after send attempt the data is %d bytes", _outputBuffer.length);
}

-(NSInteger)writeBufferSize {
    return [_outputBuffer length] - _outputBufferIndex;
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

- (NSData*)readBuffer {
    return _inputBuffer;
}

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



