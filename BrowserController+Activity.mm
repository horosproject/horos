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
#import <OsiriX Headers/NSImage+N2.h>
#import <OsiriX Headers/N2Operators.h>
#import <mach/mach_port.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#import <algorithm>
#import "NSUserDefaultsController+OsiriX.h"

@interface ActivityObserver : NSObject {
	BrowserController* _bc;
}

-(id)initWithBrowserController:(BrowserController*)bc;

@end

@implementation BrowserController (Activity)

-(void)awakeActivity {
//	tableView = [BrowserController currentBrowser].AtableView;
//	statusLabel = [BrowserController currentBrowser].AstatusLabel;
	
	[AtableView setDelegate: self];
	
	_activityCells = [[NSMutableArray alloc] init];

//	_manager = [manager retain];
	// we observe the threads array so we can release cells when they're not needed anymore
	activityObserver = [[ActivityObserver alloc] initWithBrowserController:self];
	[[ThreadsManager defaultManager] addObserver:activityObserver forKeyPath:@"threads" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial context:NULL];
	
//	AupdateStatsThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateStatsThread:) object:NULL];
//	[AupdateStatsThread start];
	
	[[AtableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:[ThreadsManager defaultManager].threadsController withKeyPath:@"arrangedObjects" options:NULL];
	
//	[NSThread detachNewThreadSelector:@selector(testThread_creator:) toTarget:self withObject:NULL];
//	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(testTimer_createThread2:) userInfo:NULL repeats:YES];
}

/*-(void)testThread_creator:(id)t {
	[[ThreadsManager defaultManager] addThread:[NSThread currentThread]];
	[NSThread currentThread].name = @"CreatorZ joinZyX";
	[[NSThread currentThread] setSupportsCancel:YES];
	int c = 0;
	while (YES) { // ![[NSThread currentThread] isCancelled]
		c++;
		[NSThread detachNewThreadSelector:@selector(testThread_dummy:) toTarget:self withObject:NULL];
		[[NSThread currentThread] setStatus:[NSString stringWithFormat:@"So far, I jungled %d threads..", c]];
		[NSThread sleepForTimeInterval:CGFloat(random()%1000)/1000*2];
	}
}

-(void)testThread_dummy:(id)obj {
	[[ThreadsManager defaultManager] addThread:[NSThread currentThread]];
	[NSThread sleepForTimeInterval:0.001];
	[[ThreadsManager defaultManager] removeThread:[NSThread currentThread]];
}

-(void)testTimer_createThread2:(NSTimer*)t {
//	NSThread* th = [NSThread detachNewThreadSelector:@selector(testThread_dummy2:) toTarget:self withObject:NULL];
//	[[ThreadsManager defaultManager] addThread:th];
}

-(void)testThread_dummy2:(id)obj {
	//
}*/


-(void)deallocActivity {
//	[AupdateStatsThread cancel];
//	[AupdateStatsThread release];
	
	[[ThreadsManager defaultManager] removeObserver:activityObserver forKeyPath:@"threads"];
	[activityObserver release];
	
	[_activityCells release];
	
    [super dealloc];
}

-(NSCell*)cellForThread:(NSThread*)thread {
	for (ThreadCell* cell in _activityCells)
		if (cell.thread == thread)
			return cell;
	
	return nil;
}

-(NSCell*) createCellForThread:(NSThread*)thread {
	NSCell* cell = [[ThreadCell alloc] initWithThread:thread manager:[ThreadsManager defaultManager] view:AtableView];
	[_activityCells addObject:cell];
	
	return [cell autorelease];
}

/*-(void)updateStatsThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
	while (![[NSThread currentThread] isCancelled]) {
		[NSThread sleepForTimeInterval:0.5];

		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

		int threadCount = [ThreadsManager defaultManager].threads.count;
		NSString *activityString = @"";
		if (threadCount>0)
		{
			activityString = [NSString stringWithFormat:NSLocalizedString(threadCount==1?@"%d thread":@"%d threads", NULL), threadCount];
		}
		[AstatusLabel performSelectorOnMainThread:@selector(setStringValue:) withObject:activityString waitUntilDone:YES];
		
		[pool release];
	}
	
	[pool release];
}*/

-(void)activity_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == [ThreadsManager defaultManager])
		if ([keyPath isEqual:@"threads"]) { // we observe the threads array so we can release cells when they're not needed anymore
			if ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntValue] == NSKeyValueChangeRemoval)
				for (NSThread* thread in [change objectForKey:NSKeyValueChangeOldKey])
				{
					id cell = [self cellForThread:thread];
					if( cell)
						[_activityCells removeObject: cell];
				}
			return;
		}
	
}

-(NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	if (tableView == AtableView)
		@try {
			id cell = [self cellForThread: [[ThreadsManager defaultManager] threadAtIndex:row]];
		
			if( cell == nil)
				cell = [self createCellForThread: [[ThreadsManager defaultManager] threadAtIndex:row]];
		
			return cell;
		} @catch (...) {
		}
	
	return NULL;
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

@implementation ActivityObserver

-(id)initWithBrowserController:(BrowserController*)bc {
	self = [super init];
	_bc = bc; // no retaining here
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	[_bc activity_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end