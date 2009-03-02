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


#import "WaitRendering.h"

@implementation WaitRendering

- (void) showWindow: (id) sender
{
	[[self window] makeKeyAndOrderFront: sender];
	[[self window] display];
	[[self window] flushWindow];
	
	displayedTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) setCancel:(BOOL) c
{
	cancel = c;
	
	[abort setHidden: !c];					[abort display];
	[currentTimeText setHidden: !c];		[currentTimeText display];
	[lastTimeText setHidden: !c];			[lastTimeText display];
}

- (void) thread:(id) sender
{
	NSAutoreleasePool               *pool=[[NSAutoreleasePool alloc] init];
	
	while( stop == NO)
	{
//		[current lockFocus];
//		[current setStringValue:[NSString stringWithFormat:@"%0.0f", (float) ([NSDate timeIntervalSinceReferenceDate] - starttime)]];
//		[current display];
//		[current unlockFocus];
//		NSLog(@"go %0.0f s", (float) ([NSDate timeIntervalSinceReferenceDate] - starttime));
//		[NSThread sleepForTimeInterval:0.2];

	//	[NSApp runModalSession:session];
	}
//	lasttime = [NSDate timeIntervalSinceReferenceDate] - starttime;
//	[NSApp abortModal];
//	[NSApp endModalSession:session];
	
    [pool release];
}

- (void) close
{
	while( [NSDate timeIntervalSinceReferenceDate] - displayedTime < 0.5)
		[NSThread sleepForTimeInterval: 0.1];
	
	[super close];
}

-(void) end
{
	if( startTime == nil) return;	// NOT STARTED
	
	[[self window] orderOut:self];
	
	if( session != nil)
	{
		[NSApp abortModal];
		[NSApp endModalSession:session];
	}
	
	if( aborted == NO && cancel == YES)
	{
		lastDuration = -[startTime timeIntervalSinceNow];
	}
	
	[startTime release];
	startTime = nil;
	
	session = nil;
	stop = YES;
}

-(void) resetLastDuration
{
	lastDuration = 0;
}

-(void) start
{
	if( startTime == nil)
	{
		aborted = NO;
		stop = NO;
		
		lastTimeFrame = 0;
		startTime = [[NSDate date] retain];
		
		if( lastDuration != 0)
		{
			long hours, minutes, seconds;
			
			hours = lastDuration;
			hours /= (60*60);
			minutes = lastDuration;
			minutes -= hours*60*60;
			minutes /= 60;
			seconds = lastDuration;
			seconds -= hours*60*60 + minutes*60;
			
			[lastTimeText setStringValue:[NSString stringWithFormat:@"Last Duration:\r%2.2d:%2.2d:%2.2d", hours, minutes, seconds]];
		}
		else [lastTimeText setStringValue:@""];
		
		[[self window] center];
		[[self window] orderFront:self];
	}
}

-(BOOL) aborted
{
	return aborted;
}

-(BOOL) run
{
	if( stop) return NO;
	if( startTime == nil) return YES;
	
	if( cancel)
	{
		NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
		
		if( session == nil) session = [NSApp beginModalSessionForWindow:[self window]];
		
		[NSApp runModalSession:session];
		
		if( thisTime - lastTimeFrame > 1.0)
		{
			NSTimeInterval  elapsedTime;
			long hours, minutes, seconds;
			
			lastTimeFrame = thisTime;
			
			elapsedTime = -[startTime timeIntervalSinceNow];
			
			hours = elapsedTime;
			hours /= (60*60);
			minutes = elapsedTime;
			minutes -= hours*60*60;
			minutes /= 60;
			seconds = elapsedTime;
			seconds -= hours*60*60 + minutes*60;
			
			[currentTimeText setStringValue:[NSString stringWithFormat:@"Elapsed Time:\r%2.2d:%2.2d:%2.2d", hours, minutes, seconds]];
			
			#if __LP64__
			#else
			UpdateSystemActivity(UsrActivity);	// avoid sleep or screen saver mode
			#endif
		}
	}
	
	return YES;
}

- (void) dealloc
{
	[string release];
	[super dealloc];
}

- (void) setString:(NSString*) str
{
	[string release];
	string = [str retain];
	
	[message setStringValue:string];
	[message display];
}

-(void) windowDidLoad
{
	[[self window] center];
	[message setStringValue:string];
	
	[progress setUsesThreadedAnimation:YES];
	[progress setIndeterminate:YES];
	[progress setAnimationDelay:0.01];
	[progress startAnimation:self];
	[lastTimeText setStringValue:@""];

//	[progress setUsesThreadedAnimation:YES];
//	[progress setIndeterminate:YES];
//	
//	session = [NSApp beginModalSessionForWindow:[self window]];
}

-(id) init:(NSString*) str
{
	self = [super initWithWindowNibName:@"WaitRendering"];
	string = [str retain];
	session = nil;
	cancel = NO;
	lastDuration = 0;
	startTime = nil;
	displayedTime = [NSDate timeIntervalSinceReferenceDate];
	
	[[self window] center];
	[[self window] setLevel: NSModalPanelWindowLevel];

	return self;
}

- (void) setCancelDelegate:(id) object
{
	cancelDelegate = object;
}

- (IBAction) abort:(id) sender
{
	stop = YES;
	aborted = YES;
	
	[cancelDelegate abort: self];
}

//- (NSProgressIndicator*) progress { return progress;}

@end
