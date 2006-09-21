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



#import <Cocoa/Cocoa.h>

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
	BOOL						cancel;
	NSModalSession				session;
}
- (id) init:(NSString*) s;
-(BOOL) run;
- (void) start;
- (void) end;
- (IBAction) abort:(id) sender;
- (void) setCancel :(BOOL) val;
-(BOOL) aborted;
- (void) setString:(NSString*) str;
@end
