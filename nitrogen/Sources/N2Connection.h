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
	//BOOL _hasBytesAvailable, _hasSpaceAvailable, _handleConnectionClose;
	NSUInteger _handleOpenCompleted, _maximumReadSizePerEvent;
	N2ConnectionStatus _status;
}

@property(readonly) NSString* address;
@property N2ConnectionStatus status;
@property NSUInteger maximumReadSizePerEvent;

+(NSData*)sendSynchronousRequest:(NSData*)request toHost:(NSHost*)host port:(NSInteger)port;
+(void)sendSynchronousRequest:(NSData*)request toHost:(NSHost*)host port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context; // -(NSInteger)dummyDataHandler:(NSData*)data context:(void*)context

-(id)initWithAddress:(NSString*)address port:(NSInteger)port;
-(id)initWithAddress:(NSString*)address port:(NSInteger)port is:(NSInputStream*)is os:(NSOutputStream*)os;

-(void)reconnect;
-(void)close;
-(void)open; // declared for overloading only
// -(void)invalidate; // TODO: why?

-(void)reconnectToAddress:(NSString*)address port:(NSInteger)port;

-(void)writeData:(NSData*)data;
-(void)handleData:(NSMutableData*)data; // overload on subclasses
-(NSInteger)availableSize;
-(NSData*)readData:(NSInteger)size;
-(NSInteger)readData:(NSInteger)size toBuffer:(void*)buffer;

-(void)connectionFinishedSendingData; // overload on subclasses

//+(BOOL)host:(NSString*)host1 isEqualToHost:(NSString*)host2;

@end


