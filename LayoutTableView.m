//
//  LayoutTableView.m
//  OsiriX
//
//  Created by Lance Pysher on 1/11/07.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "LayoutTableView.h"

//static NSString *layoutDraggingType = @"LayoutDraggingType";


@implementation LayoutTableView

- (void)awakeFromNib{
	[self registerForDraggedTypes:[NSArray arrayWithObject:@"LayoutDraggingType"]]; 
	//[self setDoubleAction:@selector(openLayout:)];
	//[self setTarget:[self dataSource]];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	// Return one of the following:
	// NSDragOperation{Copy, Link, Generic, Private, Move,
	//                 Delete, Every, None}
	if (isLocal)
		NSDragOperationMove;
	else
		NSDragOperationNone;
}



@end
