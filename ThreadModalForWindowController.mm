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


#import "ThreadModalForWindowController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "N2Debug.h"


//static NSString* const ThreadIsCurrentlyModal = @"ThreadIsCurrentlyModal";


@implementation ThreadModalForWindowController

@synthesize thread = _thread;
@synthesize docWindow = _docWindow;
@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize titleField = _titleField;
@synthesize statusField = _statusField;
@synthesize progressDetailsField = _progressDetailsField;

-(id)initWithThread:(NSThread*)thread window:(NSWindow*)docWindow {
	self = [super initWithWindowNibName:@"ThreadModalForWindow"];
	
	_docWindow = [docWindow retain];
	_thread = [thread retain];
	[[_thread threadDictionary] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExitNotification:) name:NSThreadWillExitNotification object:_thread];

	[NSApp beginSheet:self.window modalForWindow:self.docWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[self retain];

	return self;	
}

-(void)awakeFromNib {
	[self.progressIndicator setMinValue:0];
	[self.progressIndicator setMaxValue:1];
	[self.progressIndicator setUsesThreadedAnimation:YES];
	[self.progressIndicator startAnimation:self];
	
    [self.titleField bind:@"value" toObject:self.thread withKeyPath:@"name" options:NULL];
    [self.statusField bind:@"value" toObject:self.thread withKeyPath:NSThreadStatusKey options:NULL];
    [self.progressDetailsField bind:@"value" toObject:self.thread withKeyPath:NSThreadProgressDetailsKey options:NULL];
    [self.cancelButton bind:@"enabled" toObject:self.thread withKeyPath:NSThreadSupportsCancelKey options:NULL];
//	[self.cancelButton bind:@"enabled2" toObject:self.thread withKeyPath:NSThreadIsCancelledKey options:NULL];
	
	[_thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)sheetDidEndOnMainThread:(NSWindow*)sheet {
//	[[_thread threadDictionary] removeObjectForKey:ThreadIsCurrentlyModal];
	[sheet orderOut:self];
	[NSApp endSheet:sheet];
	[self release];
}

-(void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[self performSelectorOnMainThread:@selector(sheetDidEndOnMainThread:) withObject:sheet waitUntilDone:NO];
}

-(void)dealloc {
	DLog(@"[ThreadModalForWindowController dealloc]");
	
	[self.thread removeObserver:self forKeyPath:NSThreadProgressKey];
	
	[[_thread threadDictionary] release];
	[_thread release];
	[_docWindow release];
	
	[super dealloc]; 
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.thread)
		if ([keyPath isEqual:NSThreadProgressKey]) {
			[self.progressIndicator setIndeterminate: self.thread.progress < 0];	
			if (self.thread.progress >= 0)
				[self.progressIndicator setDoubleValue:self.thread.subthreadsAwareProgress];
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)invalidate {
	DLog(@"[ThreadModalForWindowController invalidate]");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:_thread];
	[NSApp endSheet:self.window];
}

-(void)threadWillExitNotification:(NSNotification*)notification {
	[self invalidate];
}

-(void)cancelAction:(id)source {
	[self.thread setIsCancelled:YES];
}

@end

@implementation NSThread (ModalForWindow)

-(ThreadModalForWindowController*)startModalForWindow:(NSWindow*)window {
//	if ([[self threadDictionary] objectForKey:ThreadIsCurrentlyModal])
//		return nil;
//	[[self threadDictionary] setObject:[NSNumber numberWithBool:YES] forKey:ThreadIsCurrentlyModal];
	if ([NSThread isMainThread]) {
		return [[[ThreadModalForWindowController alloc] initWithThread:self window:window] autorelease];
	} else [self performSelectorOnMainThread:@selector(startModalForWindow:) withObject:window waitUntilDone:NO];
	return nil;
}

@end


