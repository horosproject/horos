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
};


enum SendServerType { osirixServer, offisServer };



@class Wait;



@interface SendController : NSWindowController {
	id _server;
	NSArray *_files;
	NSString *_transferSyntaxString;
	NSString *_numberFiles;
	
	int _serverToolIndex;
	int _keyImageIndex;
	int _serverIndex;
	int _osirixTS;
	int _offisTS;
	
	IBOutlet NSComboBox	*serverList;
	IBOutlet NSMatrix	*DICOMSendTool;
	IBOutlet NSMatrix *keyImageMatrix;
	IBOutlet NSTextField *numberImagesTextField;
	IBOutlet NSPopUpButton	*syntaxListOffis;
	IBOutlet NSPopUpButton *syntaxListOsiriX;
	
	Wait *_waitSendWindow;
	BOOL _readyForRelease;
	NSLock *_lock;

}
+ (void)sendFiles:(NSArray *)files;
- (id)initWithFiles:(NSArray *)files;

- (id)serverAtIndex:(int)index;
- (id)server;

- (NSString *)numberFiles;
- (void)setNumberFiles:(NSString *)numberFiles;

- (int)serverToolIndex;
-(void)setServerToolIndex:(int)index;
- (int)keyImageIndex;
-(void)setKeyImageIndex:(int)index;
- (int) osirixTS;
- (void) setOsirixTS:(int)index;
- (int) offisTS;
- (void) setOffisTS:(int)index;

- (void)sendDICOMFiles:(NSMutableArray *)files;

- (void)releaseSelfWhenDone:(id)sender;
- (void)listenForAbort:(id)handler;






@end
