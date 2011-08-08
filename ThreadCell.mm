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

#import "ThreadCell.h"
#import "ThreadsManager.h"
#import "BrowserController.h"
#import "NSString+N2.h"
#import "NSThread+N2.h"
#import "N2Operators.h"


@implementation ThreadCell

@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize thread = _thread;
@synthesize manager = _manager;
@synthesize view = _view;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager view:(NSTableView*)view {
	self = [super init];
	
	_view = [view retain];
	_manager = [manager retain];
	
	_progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
	[_progressIndicator setUsesThreadedAnimation:YES];
	[_progressIndicator setMinValue:0];
	[_progressIndicator setMaxValue:1];
	
	_cancelButton = [[NSButton alloc] initWithFrame:NSZeroRect];
	[_cancelButton setImage:[NSImage imageNamed:@"Activity_Stop"]];
	[_cancelButton setAlternateImage:[NSImage imageNamed:@"Activity_StopPressed"]];
	[_cancelButton setBordered:NO];
	[_cancelButton setButtonType:NSMomentaryChangeButton];
	_cancelButton.target = self;
	_cancelButton.action = @selector(cancelThreadAction:);

	self.thread = thread;
	[thread.threadDictionary retain];

//	NSLog(@"cell created!");
	
	return self;
}

-(void)dealloc {
//	NSLog(@"cell destroyed!");
	[self.progressIndicator removeFromSuperview];
	[_progressIndicator release];
	
	[self.cancelButton removeFromSuperview];
	[_cancelButton release];
	
	[self.thread.threadDictionary release];
	self.thread = nil;
	
//	[_view release];
	[_manager release];
	
	[super dealloc];
}

-(void)setThread:(NSThread*)thread {
	@try {
		[self.thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
		[self.thread removeObserver:self forKeyPath:NSThreadProgressKey];
		[self.thread removeObserver:self forKeyPath:NSThreadStatusKey];
		[self.thread removeObserver:self forKeyPath:NSThreadIsCancelledKey];
	} @catch (...) {
	}
	
	[_thread release];
	_thread = [thread retain];
	
	[self.thread addObserver:self forKeyPath:NSThreadIsCancelledKey options:NSKeyValueObservingOptionInitial context:NULL];
	[self.thread addObserver:self forKeyPath:NSThreadStatusKey options:NSKeyValueObservingOptionInitial context:NULL];
	[self.thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:NULL];
	[self.thread addObserver:self forKeyPath:NSThreadSupportsCancelKey options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
	[self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.thread) {
		if (![NSThread isMainThread]) {
			[self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, obj, change, [NSValue valueWithPointer:context], NULL] waitUntilDone:NO];
			return;
		}
		
		if ([keyPath isEqual:NSThreadStatusKey]) {
			[self.view setNeedsDisplayInRect: [self.view rectOfRow:[self.manager.threads indexOfObject:self.thread]]];
			return;
		} else if ([keyPath isEqual:NSThreadProgressKey]) {
			[self.progressIndicator setDoubleValue:self.thread.subthreadsAwareProgress];
			[self.progressIndicator setIndeterminate: self.thread.progress < 0];
			[self.progressIndicator startAnimation:self];
			return;
		} else if ([keyPath isEqual:NSThreadSupportsCancelKey] || [keyPath isEqual:NSThreadIsCancelledKey]) {
			[self.cancelButton setHidden:(!self.thread.supportsCancel)||self.thread.isCancelled];
			[self.cancelButton setEnabled:self.thread.supportsCancel];
			return;
		}
	}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)cancelThreadAction:(id)source
{
	self.thread.status = NSLocalizedString( @"Cancelling...", nil);
	[self.thread setIsCancelled:YES];
}


-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view {
	if ([self.thread isFinished]) return;
	
	NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSMutableDictionary* textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: [self textColor], NSForegroundColorAttributeName, [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, NULL];

	[NSGraphicsContext saveGraphicsState];
	
	NSRect nameFrame = NSMakeRect(frame.origin.x+3, frame.origin.y-1, frame.size.width-23, frame.size.height);
	NSString* name = self.thread.name;
	if (!name) name = NSLocalizedString( @"Untitled Thread", nil);
	[name drawWithRect:nameFrame options:NSStringDrawingUsesLineFragmentOrigin+NSStringDrawingTruncatesLastVisibleLine attributes:textAttributes];
	
	NSRect statusFrame = [self statusFrame];
	[textAttributes setObject:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]] forKey:NSFontAttributeName];
	[self.thread.status drawWithRect:statusFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
	
	
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view {
//	{ // for debug
//		[NSGraphicsContext saveGraphicsState];
//		
//		[[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.25] setFill];
//		[NSBezierPath fillRect:frame];
//		
//		[NSGraphicsContext restoreGraphicsState];
//	}
	
	if ([self.thread isFinished]) return;
	
	[self drawInteriorWithFrame:frame inView:view];
	
	[NSGraphicsContext saveGraphicsState];
	
	[[[NSColor grayColor] colorWithAlphaComponent:0.5] set];
	[NSBezierPath strokeLineFromPoint:frame.origin+NSMakeSize(-2, frame.size.height) toPoint:frame.origin+frame.size+NSMakeSize(2,0)];
	
	[NSGraphicsContext restoreGraphicsState];
}

-(NSRect)statusFrame {
	NSRect frame = [self.view rectOfRow:[self.manager.threads indexOfObject:self.thread]];
	return NSMakeRect(frame.origin.x+3, frame.origin.y+13, frame.size.width-22, frame.size.height-13);
}

@end
