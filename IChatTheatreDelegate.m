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

#import "IChatTheatreDelegate.h"
#import <InstantMessage/IMService.h>
#import <InstantMessage/IMAVManager.h>
#import "ViewerController.h"

static IChatTheatreDelegate	*iChatDelegate = 0L;

@implementation IChatTheatreDelegate

+ (IChatTheatreDelegate*) releaseSharedDelegate
{
	[iChatDelegate release];
	iChatDelegate = 0L;
}

+ (IChatTheatreDelegate*) sharedDelegate
{
	if( iChatDelegate == 0L) iChatDelegate = [[IChatTheatreDelegate alloc] init];
	
	return iChatDelegate;
}

- (id)init
{
	if(![super init]) return nil;
	[[IMService notificationCenter] addObserver:self selector:@selector(_stateChanged:) name:IMAVManagerStateChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowChanged:) name:NSWindowDidBecomeKeyNotification object:nil];
	return self;
}

- (void) dealloc
{
	[[IMAVManager sharedAVManager] setVideoDataSource:nil];
	[[IMService notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)_stateChanged:(NSNotification *)aNotification;
{
	NSLog(@"IChatTheatreDelegate _stateChanged !");
    // Read the state.
	IMAVManager *avManager = [IMAVManager sharedAVManager];
    IMAVManagerState state = [avManager state];

    if(state == IMAVRequested)
	{
		isRunning = YES;
		if([[[[NSApplication sharedApplication] keyWindow] windowController] isKindOfClass:[ViewerController class]])
		{
			NSLog(@"IChatTheatreDelegate Start iChat Theatre");
			[avManager setVideoDataSource:[[[[NSApplication sharedApplication] keyWindow] windowController] imageView]];
			[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
			[avManager start];
		}
	}
	else if(state == IMAVInactive)
	{
		[avManager stop];
		NSLog(@"IChatTheatreDelegate STOP iChat Theatre");
		isRunning = NO;
	}
}

- (void)windowChanged:(NSNotification *)aNotification;
{
	if(![self isIChatTheatreRunning]) return;
	
	IMAVManager *avManager = [IMAVManager sharedAVManager];
		
	if([[[aNotification object] windowController] isKindOfClass:[ViewerController class]])
	{
		NSLog(@"IChatTheatreDelegate change video source");
		[avManager setVideoDataSource:[[[aNotification object] windowController] imageView]];
		[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
		NSLog(@"IChatTheatreDelegate Start iChat Theatre");
		[avManager start];
		isRunning = YES;
	}
	else if ([[[aNotification object] windowController] isKindOfClass:[VRController class]])
	{
		NSLog(@"IChatTheatreDelegate change video source");
		[avManager setVideoDataSource:[[[aNotification object] windowController] view]];
		[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
		NSLog(@"IChatTheatreDelegate Start iChat Theatre");
		[avManager start];
		isRunning = YES;
	}
}

- (BOOL)isIChatTheatreRunning;
{
//	return isRunning;
	if([[IMAVManager sharedAVManager] state] == IMAVInactive)
		return NO;
	return YES;
}

@end
