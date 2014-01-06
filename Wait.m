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

#import "WaitRendering.h"
#import "Wait.h"
#import "SendController.h"
#import "NSWindow+N2.h"

@implementation Wait

- (void) showWindow: (id) sender
{
	NSMutableArray *winList = [NSMutableArray array];
	
	for( NSWindow *w in [NSApp windows])
	{
		if( [w isVisible] && ([[w windowController] isKindOfClass: [WaitRendering class]] || [[w windowController] isKindOfClass: [Wait class]]))
			[winList addObject: [w windowController]];
	}
	[[self window] center];
	[[self window] setFrameTopLeftPoint: NSMakePoint( [[self window] frame].origin.x, [[self window] frame].origin.y - [winList count] * (10 + [[self window] frame].size.height))];
	
	[super showWindow: sender];
	[[self window] makeKeyAndOrderFront: sender];
	[[self window] setDelegate: self];
	
	[[self window] display];
	[[self window] flushWindow];
	[[self window] makeKeyAndOrderFront: sender];
	
	displayedTime = [NSDate timeIntervalSinceReferenceDate];
	aborted = NO;
}

- (void) close
{
	while( [NSDate timeIntervalSinceReferenceDate] - displayedTime < 0.5)
		[NSThread sleepForTimeInterval: 0.5];
	
    [[self window] orderOut:self];
    
    if( session != nil)
		[NSApp endModalSession:session];
	session = nil;
}

- (void) dealloc
{
    [self close];
    
	[startTime release];
	startTime = nil;
    
	[super dealloc];
}

- (void)incrementBy:(double)delta
{
	long hours, minutes, seconds;
	NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
	
	if( [progress doubleValue] != 0)
	{
		NSTimeInterval fullWork, intervalElapsed = -[startTime timeIntervalSinceNow];
		
		if( intervalElapsed > 1)
		{
			if( thisTime - lastTimeFrame > 1.0 && thisTime - firstTime > 10.0)
			{
				lastTimeFrame = thisTime;
				
				fullWork = (intervalElapsed * ([progress maxValue] - [progress minValue])) / [progress doubleValue];
				
				fullWork -= intervalElapsed;
				
				hours = fullWork;
				hours /= (60*60);
				minutes = fullWork;
				minutes -= hours*60*60;
				minutes /= 60;
				seconds = fullWork;
				seconds -= hours*60*60 + minutes*60;
				
				[elapsed setStringValue:[NSString stringWithFormat: NSLocalizedString( @"Estimated remaining time: %2.2d:%2.2d:%2.2d", nil), (int) hours, (int) minutes, (int) seconds]];
				[elapsed displayIfNeeded];
				
				#if __LP64__
				#else
				UpdateSystemActivity(UsrActivity);	// avoid sleep or screen saver mode
				#endif
			}
		}
	}
	else
	{
		startTime = [[NSDate date] retain];
		
		if( openSession)
			session = [NSApp beginModalSessionForWindow:[self window]];
	}
	
	[progress incrementBy:delta];
	
	if( thisTime - lastTimeFrameUpdate > 1.0)
	{
		lastTimeFrameUpdate = thisTime;
		
		[progress displayIfNeeded];
	
		if( session)
			[NSApp runModalSession: session];
	}
}

- (void) setElapsedString :(NSString*) str
{
	[elapsed setStringValue: str];
	[elapsed displayIfNeeded];
}

-(id) initWithString:(NSString*) str :(BOOL) useSession
{
	self = [super initWithWindowNibName:@"Wait"];

    [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
    
    [[self window] center];
	[[self window] setLevel: NSModalPanelWindowLevel];
	if( str) [text setStringValue:str];
	
	startTime = nil;
	lastTimeFrame = 0;
	lastTimeFrameUpdate = 0;
	session = nil;
	cancel = NO;
	aborted = NO;
	openSession = useSession;
	_target = nil;
	firstTime = [NSDate timeIntervalSinceReferenceDate];
	displayedTime = [NSDate timeIntervalSinceReferenceDate];
	
	return self;
}

-(id) initWithString:(NSString*) str
{
	return [self initWithString: str :YES];
}

-(void) setHide :(BOOL) val
{
	[[self window] setCanHide: val];
}

-(void) setCancel :(BOOL) val
{
	cancel = val;
	[abort setHidden: !val];
	[abort display];
}

- (NSProgressIndicator*) progress
{
	 return progress;
}

-(IBAction) abortButton: (id) sender
{
	aborted = YES;
	[NSApp stopModal];
}

-(BOOL) aborted
{
	return aborted;
}
@end
