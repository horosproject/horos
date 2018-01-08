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

#import "Wait.h"
#import "WaitRendering.h"
#import "NSWindow+N2.h"

@implementation WaitRendering

- (void) showWindow: (id) sender
{
	NSMutableArray *winList = [NSMutableArray array];
	
	for( NSWindow *w in [NSApp windows])
	{
		if( [w isVisible] && ([[w windowController] isKindOfClass: [WaitRendering class]] || [[w windowController] isKindOfClass: [Wait class]]))
			[winList addObject: [w windowController]];
	}
	
	if( [[self window] isVisible] == NO)
	{
		[[self window] center];
		[[self window] setFrame: NSMakeRect( [[self window] frame].origin.x, [[self window] frame].origin.y - [winList count] * (5 + [[self window] frame].size.height), [[self window] frame].size.width, [[self window] frame].size.height) display: NO];
	}
	[super showWindow: sender];
	[[self window] makeKeyAndOrderFront: sender];
	
	[self run];
	
	[[self window] display];
	[[self window] flushWindow];
	[[self window] makeKeyAndOrderFront: sender];
	
	displayedTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) setCancel:(BOOL) c
{
	supportCancel = c;
	
	[abort setHidden: !c];					[abort display];
	[currentTimeText setHidden: !c];		[currentTimeText display];
	[lastTimeText setHidden: !c];			[lastTimeText display];
}

- (void) thread:(id) sender
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	
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
	while( [NSDate timeIntervalSinceReferenceDate] - displayedTime < 0.1)
		[NSThread sleepForTimeInterval: 0.05];
	
    [[self window] orderOut:self];
    
    if( session != nil)
	{
		[NSApp endModalSession:session];
		session = nil;
	}
}

-(void) end
{
	if( startTime == nil) return;	// NOT STARTED
	
	[self close];
	
	if( aborted == NO && supportCancel == YES)
	{
		lastDuration = -[startTime timeIntervalSinceNow];
	}
	
	[startTime release];
	startTime = nil;
	
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
			
			[lastTimeText setStringValue:[NSString stringWithFormat: NSLocalizedString( @"Last Duration:\r%2.2d:%2.2d:%2.2d", nil), hours, minutes, seconds]];
		}
		else [lastTimeText setStringValue:@""];
		
		[self showWindow: self];
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
	
	if( supportCancel)
	{
		NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
		
		if( session == nil) 
            session = [NSApp beginModalSessionForWindow:[self window]];
		
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
			
			[currentTimeText setStringValue:[NSString stringWithFormat: NSLocalizedString( @"Elapsed Time:\r%2.2d:%2.2d:%2.2d", nil), hours, minutes, seconds]];
			
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
    [self close];
    
	[string release];
    string = nil;
    
    [startTime release];
	startTime = nil;
    
	[super dealloc];
}

- (void) setString:(NSString*) str
{
    if( string != str)
    {
        [string release];
        string = [str retain];
	}
    
	[message setStringValue:string];
	[message display];
}

-(void) windowDidLoad
{
	[[self window] center];
	
	[message setStringValue: string];
	[progress setUsesThreadedAnimation: YES];
	[progress setIndeterminate: YES];
	[progress startAnimation: self];
	[lastTimeText setStringValue: @""];
}

-(id) init:(NSString*) str
{
	self = [super initWithWindowNibName:@"WaitRendering"];
	string = [str retain];
	session = nil;
	supportCancel = NO;
	lastDuration = 0;
	startTime = nil;
	displayedTime = [NSDate timeIntervalSinceReferenceDate];
	
    [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
    
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
