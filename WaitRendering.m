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
//		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

	//	[NSApp runModalSession:session];
	}
//	lasttime = [NSDate timeIntervalSinceReferenceDate] - starttime;
//	[NSApp abortModal];
//	[NSApp endModalSession:session];
	
    [pool release];
}

-(void) end
{
	if( startTime == 0L) return;	// NOT STARTED
	
	[[self window] orderOut:self];
	
	NSLog(@"end");
	if( session != 0L)
	{
		[NSApp abortModal];
		[NSApp endModalSession:session];
	}
	
	if( aborted == NO && cancel == YES)
	{
		lastDuration = -[startTime timeIntervalSinceNow];
	}
	
	[startTime release];
	startTime = 0L;
	
	session = 0L;
	stop = YES;
}

-(void) start
{
	if( startTime == 0L)
	{
		aborted = NO;
		stop = NO;
		NSLog(@"start");
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
			
			[lastTimeText setStringValue:[NSString stringWithFormat:@"Last Rendering:\r%2.2d:%2.2d:%2.2d", hours, minutes, seconds]];
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
	if( startTime == 0L) return YES;
	
	if( cancel)
	{
		NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
		
		if( session == 0L) session = [NSApp beginModalSessionForWindow:[self window]];
		
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
			
			UpdateSystemActivity (1);	// avoid sleep or screen saver mode
		}
	}
	
	return YES;
}

- (void) dealloc
{
	[string release];
	[super dealloc];
}

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

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


//	[progress setUsesThreadedAnimation:YES];
//	[progress setIndeterminate:YES];
//	
//	session = [NSApp beginModalSessionForWindow:[self window]];
}

-(id) init:(NSString*) str
{
	self = [super initWithWindowNibName:@"WaitRendering"];
	string = [str retain];
	session = 0L;
	cancel = NO;
	lastDuration = 0;
	startTime = 0L;
	
	[[self window] center];
	[[self window] setLevel: NSModalPanelWindowLevel];

	return self;
}

- (IBAction) abort:(id) sender
{
	stop = YES;
	aborted = YES;
}

//- (NSProgressIndicator*) progress { return progress;}

@end
