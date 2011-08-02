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
#include <math.h>
#include <algorithm>
#include <iostream>

NSString* N2ConnectionStatusDidChangeNotification = @"N2ConnectionStatusDidChangeNotification";

@implementation N2Connection
@synthesize address = _address, status = _status;

-(id)initWithAddress:(NSString*)address port:(NSInteger)port {
	return [self initWithAddress:address port:port is:NULL os:NULL];
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
	
	if (!_lifecycle)
		_lifecycle = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(lifecycle:) userInfo:NULL repeats:YES];
}

-(void)setStatus:(N2ConnectionStatus)status {
	if (status == _status)
		return;
	
	_status = status;
	
#ifdef DEBUG
	NSString* N2ConnectionStatusName[] = {@"N2ConnectionStatusClosed", @"N2ConnectionStatusConnecting", @"N2ConnectionStatusOpening", @"N2ConnectionStatusOk"};
	NSLog(@"%@ Setting Status: %@", self, N2ConnectionStatusName[status]);
#endif	

	[[NSNotificationCenter defaultCenter] postNotificationName: N2ConnectionStatusDidChangeNotification object:self];
}

-(void)close {
	if ([self status] == N2ConnectionStatusClosed)
		return;
	[self setStatus:N2ConnectionStatusClosed];
	
	if (_lifecycle) [_lifecycle invalidate]; _lifecycle = NULL;
	
	if (_outputStream) {
		[_outputStream close];
		[_outputStream release]; _outputStream = NULL;
	}
	
	if (_inputStream) {
		[_inputStream close];
		[_inputStream release]; _inputStream = NULL;
	}
	
	[_inputBuffer setLength:0];
	[_outputBuffer setLength:0];
	
	_handleOpenCompleted = _hasBytesAvailable = _hasSpaceAvailable = _handleConnectionClose = NO;
}

-(void)invalidate {
	[self close];
}

-(void)lifecycle {
	if (_handleOpenCompleted == 2) {
		_handleOpenCompleted = NO;
		[self setStatus:N2ConnectionStatusOk];
	}
	
	if (_handleConnectionClose) {
		_handleConnectionClose = NO;
		[self close];
	}
	
	// data input and output
	
	if (_hasBytesAvailable) {
		DLog(@"%@ Has Bytes Available", self);
		_hasBytesAvailable = NO;
		
		NSUInteger maxLength = 1024; uint8_t buffer[maxLength];
		unsigned int length = [_inputStream read:buffer maxLength:maxLength];
		if (length > 0) {
			DLog(@"%@ Read %d Bytes", self, length);
			//			std::cerr << [[NSString stringWithFormat:@"%@ Read %d Bytes", self, length] UTF8String] << ": ";
			//			for (int i = 0; i < length; ++i)
			//				std::cerr << (int)buffer[i] << " ";
			//			std::cerr << std::endl;
			[_inputBuffer appendBytes:buffer length:length];
		}
		
		[self handleData:_inputBuffer];
	}
	
	if (/*_hasSpaceAvailable && */[_outputBuffer length]) {
		NSUInteger length = [_outputBuffer length];
		if (length) {
			_hasSpaceAvailable = NO;
			NSUInteger sentLength = [_outputStream write:(uint8_t*)[_outputBuffer bytes] maxLength:length];
			if (sentLength != -1) {
				DLog(@"%@ Sent %d Bytes", self, sentLength);
				[_outputBuffer replaceBytesInRange:NSMakeRange(0,sentLength) withBytes:NULL length:0];
			} else
				DLog(@"%@ Send error: %@", self, [[_outputStream streamError] localizedDescription]);
		}
	}
}

-(void)lifecycle:(NSTimer*)timer {
	[self lifecycle];
}

-(void)handleData:(NSMutableData*)data {
	[data setLength:0];
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {
#ifdef DEBUG
	NSString* NSEventName[] = {@"NSStreamEventNone", @"NSStreamEventOpenCompleted", @"NSStreamEventHasBytesAvailable", @"NSStreamEventHasSpaceAvailable", @"NSStreamEventErrorOccurred", @"NSStreamEventEndEncountered"};
	NSLog(@"%@ stream:%@ handleEvent:%@", self, stream, NSEventName[(int)log2(event)+1]);
#endif
	
	if (event == NSStreamEventOpenCompleted)
		++_handleOpenCompleted;
	if (stream == _inputStream && event == NSStreamEventHasBytesAvailable)
		_hasBytesAvailable = YES;
	if (stream == _outputStream && event == NSStreamEventHasSpaceAvailable && [_outputBuffer length])
		_hasSpaceAvailable = YES;
	if (event == NSStreamEventErrorOccurred || event == NSStreamEventEndEncountered)
		_handleConnectionClose = YES;
}

-(void)writeData:(NSData*)data {
	[_outputBuffer appendData:data];
	// the putput buffer is sent every 0.01 seconds - that's quick enough, otherwise [self transferData:NULL];
}
/*
-(NSString*)host2ipv6:(NSString*)host {
	
}

+(BOOL)host:(NSString*)host1 isEqualToHost:(NSString*)host2 {
	return [[self host2ipv6:host1] isEqual:[self host2ipv6:host2]];
}
*/
@end
