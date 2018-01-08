/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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


