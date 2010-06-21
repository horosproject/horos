//
//  ThreadModalForWindowm.m
//  ManualBindings
//
//  Created by Alessandro Volz on 2/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "ThreadModalForWindowController.h"
#import "ThreadsManager.h"
#import <OsiriX Headers/NSThread+N2.h>


@implementation ThreadModalForWindowController

@synthesize thread = _thread;
@synthesize docWindow = _docWindow;
@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize titleField = _titleField;
@synthesize statusField = _statusField;

-(id)initWithThread:(NSThread*)thread window:(NSWindow*)docWindow {
	self = [super initWithWindowNibName:@"ThreadModalForWindow"];
	
	_docWindow = [docWindow retain];
	_thread = [thread retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExitNotification:) name:NSThreadWillExitNotification object:_thread];

	[NSApp beginSheet:self.window modalForWindow:self.docWindow modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];

	return self;	
}

-(void)awakeFromNib {
	[self.progressIndicator setMinValue:0];
	[self.progressIndicator setMaxValue:1];
	[self.progressIndicator setUsesThreadedAnimation:YES];
	[self.progressIndicator startAnimation:self];
	
    [self.titleField bind:@"value" toObject:self.thread withKeyPath:@"name" options:NULL];
    [self.statusField bind:@"value" toObject:self.thread withKeyPath:NSThreadStatusKey options:NULL];
    [self.cancelButton bind:@"enabled" toObject:self.thread withKeyPath:NSThreadSupportsCancelKey options:NULL];
    [self.cancelButton bind:@"enabled2" toObject:self.thread withKeyPath:NSThreadIsCancelledKey options:NULL];
	
	[_thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)dealloc {
	[self.thread removeObserver:self forKeyPath:NSThreadProgressKey];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:_thread];
	
	[_thread release];
	[_docWindow release];
	
	[super dealloc]; 
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.thread)
		if ([keyPath isEqual:NSThreadProgressKey]) {
			[self.progressIndicator setIndeterminate: self.thread.progress < 0];	
			if (self.thread.progress >= 0)
				[self.progressIndicator setDoubleValue:self.thread.progress];
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)threadWillExitNotification:(NSNotification*)notification {
	[NSApp endSheet:self.window];
	[self close];
	[self autorelease];
}

-(void)cancelAction:(id)source {
	[self.thread setIsCancelled:YES];
}

@end

@implementation NSThread (ModalForWindow)

-(void)startModalForWindow:(NSWindow*)window {
	if ([NSThread isMainThread])
		[[ThreadModalForWindowController alloc] initWithThread:self window:window];
	else [self performSelectorOnMainThread:@selector(startModalForWindow:) withObject:window waitUntilDone:NO];
}

@end


