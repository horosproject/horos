//
//  NFIWindow.m
//  iLife Window
//
//  Created by Sean Patrick O'Brien on 9/15/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFIWindow.h"
#import "NFIFrame.h"

@implementation NFIWindow

+ (Class)frameViewClassForStyleMask:(unsigned int)styleMask
{
	return [NFIFrame class];
}

- (float)titleBarHeight
{
	return [_borderView titleBarHeight];
}

- (void)setTitleBarHeight:(float)height
{
	[_borderView setTitleBarHeight: height];
}

- (float)bottomBarHeight
{
	return [_borderView bottomBarHeight];
}

- (void)setBottomBarHeight:(float)height
{
	[_borderView setBottomBarHeight: height];
}

- (float)midBarHeight
{
	return [_borderView midBarHeight];
}

- (float)midBarOriginY
{
	return [_borderView midBarOriginY];;
}

- (void)setMidBarHeight:(float)height origin:(float)origin
{
	[_borderView setMidBarHeight: height origin:origin];
}

@end
