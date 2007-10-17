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


/** \brief Window Controller for the Wait Panel */
@interface Wait : NSWindowController
{
    IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField		 *text, *elapsed;
	IBOutlet NSButton			 *abort;
	
	id _target;
	NSDate  *startTime;
	BOOL	cancel, aborted, openSession;
	NSModalSession session;
	NSTimeInterval lastTimeFrame, lastTimeFrameUpdate, firstTime;
}

- (void)incrementBy:(double)delta;
- (NSProgressIndicator*) progress;
- (id) initWithString:(NSString*) str;
- (id) initWithString:(NSString*) str :(BOOL) useSession;
- (BOOL) aborted;
- (IBAction) abortButton: (id) sender;
- (void) setCancel :(BOOL) val;
- (void) setElapsedString :(NSString*) str;
- (void)setTarget:(id)target;
@end
