/*=========================================================================
  Program:   OsiriX

  Copyright(c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "FlyThruTableView.h"


#define FlyThruTableViewDataType @"FlyThruTableViewDataType"

@implementation FlyThruTableView

 //drag and drop delegates
 - (void)awakeFromNib
{
	NSLog(@"awake from nib");
    [self  registerForDraggedTypes:
                        [NSArray arrayWithObject:FlyThruTableViewDataType]];
	[self setVerticalMotionCanBeginDrag:YES];
 
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
	tableColumns:(NSArray *)tableColumns 
	event:(NSEvent *)dragEvent 
	offset:(NSPointPointer)dragImageOffset{
	
	return [[[[self delegate] selectedObjects] objectAtIndex:0] previewImage];
}


- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint{
	return YES;
}



@end
