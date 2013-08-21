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
#import "N2Debug.h"

@interface BrowserActivityHelper : NSObject <NSTableViewDataSource> {
	BrowserController* _browser;
	NSMutableArray* _cells;
}

-(id)initWithBrowser:(BrowserController*)browser;

@end


@implementation BrowserController (Activity)

-(void)awakeActivity
{
	_activityHelper = [[BrowserActivityHelper alloc] initWithBrowser:self];
	[_activityTableView setDelegate: _activityHelper];
    [_activityTableView setDataSource: _activityHelper];
	
//	[_activityTableView bind:@"content" toObject:[ThreadsManager defaultManager].threadsController withKeyPath:@"arrangedObjects" options:NULL];
//	[[_activityTableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:[ThreadsManager defaultManager].threadsController withKeyPath:@"arrangedObjects" options:NULL];
}

-(void)deallocActivity
{
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
    [ThreadsManager.defaultManager.threadsController removeObserver:self forKeyPath: @"arrangedObjects"];
	[super dealloc];
}

-(NSCell*)cellForThread:(NSThread*)thread {
    
    @synchronized (ThreadsManager.defaultManager.threadsController) {
        for (ThreadCell* cell in _cells)
            if (cell.thread == thread)
                return cell;
    }
	return nil;
}

-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
    [self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(NSArrayController*)object change:(NSDictionary*)change context:(void*)context {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, object, change, [NSValue valueWithPointer:context], nil] waitUntilDone:NO];
        return;
    }

	if (context == BrowserActivityHelperContext) {
        @synchronized (ThreadsManager.defaultManager.threadsController) {
            // we are looking for removed threads
            NSMutableArray* threadsThatHaveCellsToRemove = [[[_cells valueForKey:@"thread"] mutableCopy] autorelease];
            [threadsThatHaveCellsToRemove removeObjectsInArray:object.arrangedObjects];
            
            NSMutableArray *cellsToRemove = [NSMutableArray array];
            for (NSThread* thread in threadsThatHaveCellsToRemove)
            {
                ThreadCell* cell = (ThreadCell*)[self cellForThread:thread];
                if (cell)
                {
                    [cell cleanup];
                    [cell retain];
                    [cellsToRemove addObject:cell];
                    
                    [NSObject cancelPreviousPerformRequestsWithTarget: cell selector: @selector( autorelease) object: nil];
                    [cell performSelector: @selector( autorelease) withObject: nil afterDelay: 60]; //Yea... I know... not very nice, but avoid a zombie crash, if a thread is cancelled (GUI) AFTER released here...
                }
            }
            
            BOOL needToReloadData = NO;
            
            if( cellsToRemove.count)
            {
                [_cells removeObjectsInArray: cellsToRemove];
                needToReloadData = YES;
            }
            
            // Check for new added threads
            for (NSThread *thread in object.arrangedObjects)
            {
                id cell = [self cellForThread: thread];
                if (cell == nil)
                {
                    [_cells addObject: [[[ThreadCell alloc] initWithThread:thread manager:ThreadsManager.defaultManager view:_browser._activityTableView] autorelease]];
                    needToReloadData = YES;
                }
            }
            
            if( needToReloadData)
                [_browser._activityTableView reloadData];
            
            return;
        }
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(NSCell*)tableView:(NSTableView*)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	@try
    {
        @synchronized (ThreadsManager.defaultManager.threadsController)
        {
            id cell = [[_cells objectAtIndex: row] retain];
            return [cell autorelease];
        }
    }
    @catch (...) {
	}
	
	return NULL;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    @synchronized (ThreadsManager.defaultManager.threadsController) {
        return _cells.count;
    }
    
    return 0;
}

-(void)tableView:(NSTableView*)tableView willDisplayCell:(ThreadCell*)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	NSRect frame;
	if (tableColumn) frame = [tableView frameOfCellAtColumn:[tableView.tableColumns indexOfObject:tableColumn] row:row];
	else frame = [tableView rectOfRow:row];
	
    @synchronized (ThreadsManager.defaultManager.threadsController)
    {
        if( [_cells containsObject: cell])
        {
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
    }
}

@end