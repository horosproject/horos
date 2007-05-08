//
//  SendController.h
//  OsiriX
//
//  Created by Lance Pysher on 12/14/05.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

//Abstract class for generalized control of DICOM sending.

#import <Cocoa/Cocoa.h>

enum TransferSyntaxCodes
{
	SendExplicitLittleEndian		= 0, 
	SendJPEG2000Lossless,
	SendJPEG2000Lossy10, 
	SendJPEG2000Lossy20,
	SendJPEG2000Lossy50,
	SendJPEGLossless, 
	SendJPEGLossy9,
	SendJPEGLossy8,
	SendJPEGLossy7,
	SendImplicitLittleEndian,
	SendRLE,
	SendExplicitBigEndian,
	SendBZip,

};


enum SendServerType { osirixServer, offisServer };

@class Wait;
@class DCMTKStoreSCU;

@interface SendController : NSWindowController {
	id					_server;
	NSArray				*_files;
	NSString			*_transferSyntaxString;
	NSString			*_numberFiles;
	int					_keyImageIndex;
	int					_serverIndex;
	int					_offisTS;
	Wait				*_waitSendWindow;
	BOOL				_readyForRelease;
	BOOL				_abort;
	NSLock				*_lock;
	DCMTKStoreSCU		*storeSCU;
	
	IBOutlet NSComboBox		*serverList;
	IBOutlet NSMatrix		*keyImageMatrix;
	IBOutlet NSTextField	*numberImagesTextField, *addressAndPort;
	IBOutlet NSPopUpButton	*syntaxListOffis;
}
+ (void)sendFiles:(NSArray *)files;
+ (int) sendControllerObjects;
- (id)initWithFiles:(NSArray *)files;
- (id)serverAtIndex:(int)index;
- (id)server;
- (NSString *)numberFiles;
- (void)setNumberFiles:(NSString *)numberFiles;
- (IBAction) endSelectServer:(id) sender;
- (int)keyImageIndex;
- (void)setKeyImageIndex:(int)index;
- (int) offisTS;
- (void) setOffisTS:(int)index;
- (void)releaseSelfWhenDone:(id)sender;
- (void)listenForAbort:(id)handler;
- (void)abort;
- (void)closeSendPanel:(id)sender;
- (IBAction)selectServer: (id)sender;
@end
