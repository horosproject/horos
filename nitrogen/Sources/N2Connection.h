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

extern const NSString* N2ConnectionStatusDidChangeNotification;

enum N2ConnectionStatus {
	N2ConnectionStatusClosed = 0,
	N2ConnectionStatusConnecting,
	N2ConnectionStatusOpening,
	N2ConnectionStatusOk
};

@interface N2Connection : NSObject {
	NSString* _address;
	NSInteger _port;
	NSInputStream* _inputStream;
	NSOutputStream* _outputStream;
	NSMutableData *_inputBuffer, *_outputBuffer;
	NSTimer* _lifecycle;
	BOOL _hasBytesAvailable, _hasSpaceAvailable, _handleConnectionClose;
	NSUInteger _handleOpenCompleted;
	N2ConnectionStatus _status;
}

@property(readonly) NSString* address;
@property N2ConnectionStatus status;

-(id)initWithAddress:(NSString*)address port:(NSInteger)port;
-(id)initWithAddress:(NSString*)address port:(NSInteger)port is:(NSInputStream*)is os:(NSOutputStream*)os;

-(void)open;
-(void)reconnect;
-(void)close;
-(void)invalidate;

-(void)reconnectToAddress:(NSString*)address port:(NSInteger)port;

-(void)lifecycle;
-(void)writeData:(NSData*)data;
-(void)handleData:(NSMutableData*)data;

@end
