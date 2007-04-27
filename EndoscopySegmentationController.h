//
//  EndoscopySegmentationController.h
//  OsiriX
//
//  Created by Lance Pysher on 4/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OSIPoint3D.h"

@class ViewerController;
@interface EndoscopySegmentationController : NSWindowController {
	ViewerController		*_viewer, *_resultsViewer;
	NSMutableArray			*_seeds;
	NSPoint					_startingPoint;
}

- (NSArray *)seeds;
- (void)addSeed:(id)seed;
- (IBAction)calculate: (id)sender;

@end
