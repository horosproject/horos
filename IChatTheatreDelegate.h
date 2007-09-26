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
#import <WebKit/WebView.h>

@interface IChatTheatreDelegate : NSObject {
	BOOL _hasChanged;
	IBOutlet WebView *web;
}

@property(readonly) WebView *web;

+ (IChatTheatreDelegate*) sharedDelegate;
+ (IChatTheatreDelegate*) releaseSharedDelegate;
- (void)_stateChanged:(NSNotification *)aNotification;
- (BOOL)isIChatTheatreRunning;

- (void)setVideoDataSource:(NSWindow*)window;

- (void)drawImage:(NSImage *)image inBounds:(NSRect)rect;
- (BOOL)_checkHasChanged:(BOOL)flag;
- (BOOL)checkHasChanged;

- (void)showIChatHelp;

@end
