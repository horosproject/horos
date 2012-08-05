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
#import <WebKit/WebView.h>

/** \brief Delegate for managing iChat Theatre */

@interface IChatTheatreDelegate : NSObject {
	BOOL _hasChanged;
	IBOutlet WebView *web;
}

@property(readonly) WebView *web;

/** Shared delegate for iChat Theater */
+ (IChatTheatreDelegate*) sharedDelegate;

/** Release the shared delegate */
+ (void) releaseSharedDelegate;
+ (IChatTheatreDelegate*) initSharedDelegate;

/** Notification sent iChat Theater state has changed */
- (void)_stateChanged:(NSNotification *)aNotification;

/** Flag to indicate if iChat Theater is running */
- (BOOL)isIChatTheatreRunning;

/** Set the window to use as the data source */
- (void)setVideoDataSource:(NSWindow*)window;


/** draw image for iChat Theater
*  We synchronise to make sure we're not drawing in two threads 
* simultaneously. */
- (void)drawImage:(NSImage *)image inBounds:(NSRect)rect;


/** The _hasChanged flag is set to 'NO' after any check (by a client of this 
* class), and 'YES' after a frame is drawn that is not identical to the 
* previous one (in the drawInBounds: method).
* Returns the current state of the flag, and sets it to the passed in value.
*/
- (BOOL)_checkHasChanged:(BOOL)flag;



/** Calling with 'NO' clears _hasChanged after the call (see above).
*/
- (BOOL)checkHasChanged;

/** Show help window for iChat theater */
- (void)showIChatHelp;

@end
