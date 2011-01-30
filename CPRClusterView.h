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

#import <Cocoa/Cocoa.h>

// poor name, think of a better one later
// this is the container view that hold the CPRview and the three transverse views

@interface CPRClusterView : NSView {
    NSView *_mainView;
    NSView *_topView;
    NSView *_middleView;
    NSView *_bottomView;
}

@property (nonatomic, readwrite, retain) IBOutlet NSView *mainView;
@property (nonatomic, readwrite, retain) IBOutlet NSView *topView;
@property (nonatomic, readwrite, retain) IBOutlet NSView *middleView;
@property (nonatomic, readwrite, retain) IBOutlet NSView *bottomView;

@end
