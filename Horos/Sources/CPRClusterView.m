/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


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











