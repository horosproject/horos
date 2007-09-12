//
//  IChatTheatreDelegate.m
//  OsiriX
//
//  Created by joris on 9/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IChatTheatreDelegate.h"
#import <InstantMessage/IMService.h>
#import <InstantMessage/IMAVManager.h>
#import "ViewerController.h"

@implementation IChatTheatreDelegate

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
	}
}

- (void)windowChanged:(NSNotification *)aNotification;
{
	IMAVManager *avManager = [IMAVManager sharedAVManager];
	if([[[aNotification object] windowController] isKindOfClass:[ViewerController class]])
	{
		NSLog(@"IChatTheatreDelegate change video source");
		[avManager setVideoDataSource:[[[aNotification object] windowController] imageView]];
		[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
		NSLog(@"IChatTheatreDelegate Start iChat Theatre");
		[avManager start];
	}
}

@end
