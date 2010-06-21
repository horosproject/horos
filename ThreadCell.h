//
//  ThreadInfoCell.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ThreadsManager;

@interface ThreadCell : NSTextFieldCell {
	NSProgressIndicator* _progressIndicator;
	ThreadsManager* _manager;
	NSButton* _cancelButton;
	NSThread* _thread;
	NSTableView* _view;
}

@property(retain) NSProgressIndicator* progressIndicator;
@property(retain) NSButton* cancelButton;
@property(retain) NSThread* thread;
@property(retain, readonly) ThreadsManager* manager;
@property(retain, readonly) NSTableView* view;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager view:(NSTableView*)view;

-(NSRect)statusFrame;

@end
