//
//  ThreadModalForWindow.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//


@class ThreadsManagerThreadInfo;

@interface ThreadModalForWindowController : NSWindowController {
	NSThread* _thread;
	NSWindow* _docWindow;
	NSProgressIndicator* _progressIndicator;
	NSButton* _cancelButton;
	NSTextField* _titleField;
	NSTextField* _statusField;
}

@property(retain, readonly) NSThread* thread;
@property(retain, readonly) NSWindow* docWindow;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(retain) IBOutlet NSButton* cancelButton;
@property(retain) IBOutlet NSTextField* titleField;
@property(retain) IBOutlet NSTextField* statusField;

-(id)initWithThread:(NSThread*)thread window:(NSWindow*)window;

-(IBAction)cancelAction:(id)source;

@end


@interface NSThread (ModalForWindow)

-(void)startModalForWindow:(NSWindow*)window;

@end;