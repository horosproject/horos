/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

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
