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

#import "OrthogonalMPRController.h"
#import "OrthogonalMPRPETCTView.h"
#import "OrthogonalMPRPETCTController.h"


@implementation OrthogonalMPRPETCTView

- (void) dealloc
{
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	blendingFactor = 0.5f;
	return self;
}

- (void) setCrossPosition: (float) x: (float) y
{
	if(crossPositionX == x && crossPositionY == y)
		return;
	crossPositionX = x;
	crossPositionY = y;
	[(OrthogonalMPRPETCTController*)controller setCrossPosition: x: y: self];
}

-(void) setBlendingFactor:(float) f
{
	[controller setBlendingFactor:f];
}

-(void) superSetBlendingFactor:(float) f
{
	[super setBlendingFactor:f];
}

- (void) flipVertical:(id) sender
{
	[(OrthogonalMPRPETCTController*)controller flipVertical: sender : self];
}

- (void) superFlipVertical:(id) sender
{
	[super flipVertical: sender];
}

- (void) flipHorizontal:(id) sender
{
	[(OrthogonalMPRPETCTController*)controller flipHorizontal: sender : self];
}

- (void) superFlipHorizontal:(id) sender
{
	[super flipHorizontal: sender];
}

- (BOOL) becomeFirstResponder
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
	
	return [super becomeFirstResponder];
}

@end
