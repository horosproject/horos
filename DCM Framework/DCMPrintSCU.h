/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "DCMSOPClass.h"

@class DCMNCreateRequest;
@class DCMPrintResponseHandler;
@class DCMObject;
@class DCMTransferSyntax;
@interface DCMPrintSCU : DCMSOPClass {
	NSArray *_imagesToPrint;
	DCMPrintResponseHandler *_dataHandler;
	DCMNCreateRequest *_filmSession;
	DCMObject *_sessionObject;
	int _filmRows;
	int _filmColumns;
	unsigned char _usePresentationContextID;
	DCMTransferSyntax *_transferSyntax;
	BOOL _isColor;
}

- (DCMNCreateRequest *)filmSession;
- (DCMObject *)sessionObject;
- (BOOL)createFilmBox;
- (BOOL)createImageBox;
- (BOOL)print;

@end
