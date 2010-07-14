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
