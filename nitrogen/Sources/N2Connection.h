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

extern NSString* N2ConnectionStatusDidChangeNotification;

enum N2ConnectionStatus {
	N2ConnectionStatusClosed = 0,
	N2ConnectionStatusConnecting,
	N2ConnectionStatusOpening,
	N2ConnectionStatusOk
};

@interface N2Connection : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5)
<NSStreamDelegate>
#endif
{
	id _address;
	NSInteger _port;
	NSInputStream* _inputStream;
	NSOutputStream* _outputStream;
	NSMutableData *_inputBuffer, *_outputBuffer;
	//BOOL _hasBytesAvailable, _hasSpaceAvailable, _handleConnectionClose;
	NSUInteger _handleOpenCompleted, _maximumReadSizePerEvent, _handleHasSpaceAvailable, _outputBufferIndex;
	NSInteger _status;
	BOOL _tlsFlag;
    BOOL _closeOnRemoteClose, _closeWhenDoneSending, _closeOnNextSpaceAvailable, _handlingData;
    NSError* _error;
    NSTimeInterval lastEventTimeInterval;
}

@property(readonly) NSString* address;
@property(readonly) NSTimeInterval lastEventTimeInterval;
@property(nonatomic) NSInteger status;
@property NSUInteger maximumReadSizePerEvent;
@property BOOL closeOnRemoteClose;
@property BOOL closeWhenDoneSending;
@property BOOL closeOnNextSpaceAvailable;
@property(readonly,retain) NSError* error;

// non-tls
+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(id)address port:(NSInteger)port;
+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(id)address port:(NSInteger)port dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context; // -(NSInteger)connection:(N2Connection*)connection dummyDataHandler:(NSData*)data context:(void*)context
-(id)initWithAddress:(id)address port:(NSInteger)port;
-(id)initWithAddress:(id)address port:(NSInteger)port is:(NSInputStream*)is os:(NSOutputStream*)os;

// generic
+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(id)address port:(NSInteger)port tls:(BOOL)tlsFlag;
+(NSData*)sendSynchronousRequest:(NSData*)request toAddress:(id)address port:(NSInteger)port tls:(BOOL)tlsFlag dataHandlerTarget:(id)target selector:(SEL)selector context:(void*)context; // -(NSInteger)connection:(N2Connection*)connection dummyDataHandler:(NSData*)data context:(void*)context
-(id)initWithAddress:(id)address port:(NSInteger)port tls:(BOOL)tlsFlag;
-(id)initWithAddress:(id)address port:(NSInteger)port tls:(BOOL)tlsFlag is:(NSInputStream*)is os:(NSOutputStream*)os;

-(void)reconnect;
-(void)close;
-(void)open; // declared for overloading only
// -(void)invalidate; // TODO: why?

-(void)startTLS;
-(BOOL)isSecure;

-(void)reconnectToAddress:(id)address port:(NSInteger)port;

-(void)writeData:(NSData*)data;
-(NSInteger)writeBufferSize;
-(void)handleData:(NSMutableData*)data; // overload on subclasses
-(NSInteger)availableSize;
-(NSData*)readData:(NSInteger)size;
-(NSInteger)readData:(NSInteger)size toBuffer:(void*)buffer;

- (NSData*)readBuffer;

-(void)connectionFinishedSendingData; // overload on subclasses

-(void)trySendingDataNow; //...

//+(BOOL)host:(NSString*)host1 isEqualToHost:(NSString*)host2;

@end


