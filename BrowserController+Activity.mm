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

#import "BrowserController+Activity.h"
#import "ThreadsManager.h"
#import "ThreadCell.h"
#import "NSImage+N2.h"
#import "N2Operators.h"
#import "NSThread+N2.h"
#import <mach/mach_port.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#import <algorithm>
#import "NSUserDefaultsController+OsiriX.h"
#import "AppController.h"

@interface BrowserActivityHelper : NSObject {
	BrowserController* _browser;
	NSMutableArray* _cells;
}

-(id)initWithBrowser:(BrowserController*)browser;

@end


@implementation BrowserController (Activity)

-(void)awakeActivity {
//	tableView = [BrowserController currentBrowser]._activityTableView;
//	statusLabel = [BrowserController currentBrowser]._activityTableView;
	
	
	_activityHelper = [[BrowserActivityHelper alloc] initWithBrowser:self];
	[_activityTableView setDelegate: _activityHelper];
	

//	_manager = [manager retain];
	
//	AupdateStatsThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateStatsThread:) object:NULL];
//	[AupdateStatsThread start];

	[_activityTableView bind:@"content" toObject:[ThreadsManager defaultManager].threadsController withKeyPath:@"arrangedObjects" options:NULL];
	[[_activityTableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:[ThreadsManager defaultManager].threadsController withKeyPath:@"arrangedObjects" options:NULL];
	
	
	
	
	//[NSThread detachNewThreadSelector:@selector(testThread_creator:) toTarget:self withObject:NULL];
}

/*-(void)testThread_creator:(id)t {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	[[ThreadsManager defaultManager] addThreadAndStart:[NSThread currentThread]];
	[NSThread currentThread].name = @"CreatorZ joinZyX";
	[[NSThread currentThread] setSupportsCancel:YES];
	int c = 0;
	while (YES) { // ![[NSThread currentThread] isCancelled]
		c++;
		[NSThread detachNewThreadSelector:@selector(testThread_dummy:) toTarget:self withObject:NULL];
		[[NSThread currentThread] setStatus:[NSString stringWithFormat:@"So far, I jungled %d threads..", c]];
		[NSThread sleepForTimeInterval:CGFloat(random()%1000)/1000*2];
	}
	
	[pool release];
}

-(void)testThread_dummy:(id)obj {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];

	[[ThreadsManager defaultManager] addThreadAndStart:[NSThread currentThread]];
	[NSThread sleepForTimeInterval:0.5];
	
	[pool release];
}*/



-(void)deallocActivity {
//	[AupdateStatsThread cancel];
//	[AupdateStatsThread release];
	
	[[ThreadsManager defaultManager] removeObserver:_activityHelper forKeyPath:@"threads"];
	[_activityHelper release];
	
    [super dealloc];
}

-(NSTableView*)_activityTableView {
	return _activityTableView;
}

@end


@implementation ThreadsTableView

-(void)selectRowIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)extend {
}

-(void)mouseDown:(NSEvent*)evt {
}

-(void)rightMouseDown:(NSEvent*)evt {
}

@end

@implementation BrowserActivityHelper

static NSString* const BrowserActivityHelperContext = @"BrowserActivityHelperContext";

-(id)initWithBrowser:(BrowserController*)browser {
	if ((self = [super init])) {
		_browser = browser; // no retaining here
		_cells = [[NSMutableArray alloc] init];

		// we observe the threads array so we can release cells when they're not needed anymore
		[ThreadsManager.defaultManager.threadsController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial context:BrowserActivityHelperContext];
	}
	
	return self;
}

-(void)dealloc {
	[_cells release];
	[super dealloc];
}

-(NSCell*)cellForThread:(NSThread*)thread {
	for (ThreadCell* cell in _cells)
		if (cell.thread == thread)
			return cell;
	return nil;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(NSArrayController*)object change:(NSDictionary*)change context:(void*)context {
	if (context == BrowserActivityHelperContext) {
		// we are looking for removed threads
		NSMutableArray* threadsThatHaveCellsToRemove = [[[_cells valueForKey:@"thread"] mutableCopy] autorelease];
		[threadsThatHaveCellsToRemove removeObjectsInArray:object.arrangedObjects];
		
		for (NSThread* thread in threadsThatHaveCellsToRemove) {
			id cell = [self cellForThread:thread];
			if (cell)
				[_cells removeObject:cell];
		}
		
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(NSCell*)tableView:(NSTableView*)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	@try {
		id cell = [self cellForThread: [[ThreadsManager defaultManager] threadAtIndex:row]];
		if (cell == nil) {
			[_cells addObject: cell = [[[ThreadCell alloc] initWithThread:[[ThreadsManager defaultManager] threadAtIndex:row] manager:ThreadsManager.defaultManager view:_browser._activityTableView] autorelease]];
		}
		
		return cell;
	} @catch (...) {
	}
	
	return NULL;
}

-(void)tableView:(NSTableView*)tableView willDisplayCell:(ThreadCell*)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	NSRect frame;
	if (tableColumn) frame = [tableView frameOfCellAtColumn:[tableView.tableColumns indexOfObject:tableColumn] row:row];
	else frame = [tableView rectOfRow:row];
	
	// cancel
	
	if (![cell.cancelButton superview])
		[tableView addSubview:cell.cancelButton];

	NSRect cancelFrame = NSMakeRect(frame.origin.x+frame.size.width-15-5, frame.origin.y+5, 15, 15);
	if (!NSEqualRects(cell.cancelButton.frame, cancelFrame))
		[cell.cancelButton setFrame:cancelFrame];	
	
	// progress
	
	if (![cell.progressIndicator superview]) {
		[tableView addSubview:cell.progressIndicator];
//		[self.progressIndicator startAnimation:self];
	}
	
    NSRect progressFrame;
    if ([AppController hasMacOSXLion])
        progressFrame = NSMakeRect(frame.origin.x+3, frame.origin.y+27, frame.size.width-6, frame.size.height-32);
    else progressFrame = NSMakeRect(frame.origin.x+1, frame.origin.y+26, frame.size.width-2, frame.size.height-28);
        
	if (!NSEqualRects(cell.progressIndicator.frame, progressFrame))
		[cell.progressIndicator setFrame:progressFrame];
}

@end