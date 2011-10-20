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

/** \brief Window Controller for Wait rendering */
@interface WaitRendering : NSWindowController
{
    IBOutlet NSProgressIndicator *progress;
	IBOutlet NSButton		     *abort;
	IBOutlet NSTextField		 *message, *currentTimeText, *lastTimeText;
	
	NSString					*string;
	NSTimeInterval				lastDuration, lastTimeFrame;
	NSDate						*startTime;
	
	BOOL						aborted;
	volatile BOOL				stop;
	BOOL						supportCancel;
	NSModalSession				session;
	
	id							cancelDelegate;
	
	NSTimeInterval				displayedTime;
	
	NSWindow					*sheetForWindow;
}

- (id) init:(NSString*) s;
- (BOOL) run;
- (void) start;
- (void) end;
- (IBAction) abort:(id) sender;
- (void) setCancel :(BOOL) val;
- (BOOL) aborted;
- (void) setString:(NSString*) str;
- (void) setCancelDelegate:(id) object;
- (void) resetLastDuration;
@end
