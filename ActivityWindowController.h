//
//  ThreadsWindowController.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ThreadsManager;

@interface ActivityWindowController : NSWindowController {
	ThreadsManager* _manager;
	NSMutableArray* _cells;
    IBOutlet NSTableView* tableView;
	IBOutlet NSImageView* cpuActiView;
	IBOutlet NSImageView* hddActiView;
	IBOutlet NSImageView* netActiView;
    IBOutlet NSTextField* statusLabel;
	NSThread* updateStatsThread;
}

@property(readonly) ThreadsManager* manager;
@property(retain) NSTableView* tableView;
@property(retain) NSTextField* statusLabel;
@property(retain) NSImageView* cpuActiView;
@property(retain) NSImageView* hddActiView;
@property(retain) NSImageView* netActiView;

+(ActivityWindowController*)defaultController;

-(id)initWithManager:(ThreadsManager*)manager;

@end


@interface ThreadsTableView : NSTableView
@end
