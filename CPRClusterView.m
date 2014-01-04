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


#import "CPRClusterView.h"

@interface CPRClusterView ()

- (void)_updateClusterViewFrames;

@end


@implementation CPRClusterView

@synthesize mainView = _mainView;
@synthesize topView = _topView;
@synthesize middleView = _middleView;
@synthesize bottomView = _bottomView;

- (void)dealloc
{
    [_mainView release];
    _mainView = nil;
    [_topView release];
    _topView = nil;
    [_middleView release];
    _middleView = nil;
    [_bottomView release];
    _bottomView = nil;
    [super dealloc];
}

- (void)setMainView:(NSView *)mainView
{
    if (mainView != _mainView) {
        [_mainView release];
        _mainView = [mainView retain];
        [self _updateClusterViewFrames];
    }
}

- (void)setTopView:(NSView *)topView
{
    if (topView != _topView) {
        [_topView release];
        _topView = [topView retain];
        [self _updateClusterViewFrames];
    }
}

- (void)setMiddleView:(NSView *)middleView
{
    if (middleView != _middleView) {
        [_middleView release];
        _middleView = [middleView retain];
        [self _updateClusterViewFrames];
    }
}

- (void)setBottomView:(NSView *)bottomView
{
    if (bottomView != _bottomView) {
        [_bottomView release];
        _bottomView = [bottomView retain];
        [self _updateClusterViewFrames];
    }
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    
    [self _updateClusterViewFrames];
}

- (void)_updateClusterViewFrames
{
    NSDisableScreenUpdates();
    
    CGFloat rightViewHeight;
    CGFloat rightViewWidth;
    CGFloat rightViewX;
    
    rightViewHeight = NSHeight(self.bounds)/3;
    rightViewHeight = floor(rightViewHeight);
    
    rightViewWidth = MIN(rightViewHeight, NSWidth(self.bounds));
    rightViewX = NSWidth(self.bounds) - rightViewWidth;
    
    _bottomView.translatesAutoresizingMaskIntoConstraints = YES;
    _middleView.translatesAutoresizingMaskIntoConstraints = YES;
    _topView.translatesAutoresizingMaskIntoConstraints = YES;
    _mainView.translatesAutoresizingMaskIntoConstraints = YES;
    
    [_bottomView setFrame:NSMakeRect(rightViewX, 0, rightViewWidth, rightViewHeight)];
    [_middleView setFrame:NSMakeRect(rightViewX, rightViewHeight, rightViewWidth, rightViewHeight)];
    [_topView setFrame:NSMakeRect(rightViewX, rightViewHeight*2.0, rightViewWidth, NSHeight(self.bounds) - 2.0*rightViewHeight)];
    
    [_mainView setFrame:NSMakeRect(0, 0, rightViewX, NSHeight(self.bounds))];
    
     NSEnableScreenUpdates();
}

@end











