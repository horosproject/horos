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
#import "NSView+N2.h"

@class N2View;

@interface N2Layout : NSObject<OptimalSize> {
	N2View* _view;
	NSControlSize _controlSize;
	BOOL _forcesSuperviewHeight, _forcesSuperviewWidth;
// private:
	NSRect _margin;
	NSSize _separation;
	BOOL _layingOut, _enabled;
}

@property(readonly) N2View* view;
@property NSControlSize controlSize;
@property BOOL forcesSuperviewHeight;
@property BOOL forcesSuperviewWidth;
@property NSRect margin;
@property NSSize separation;
@property BOOL enabled;

-(id)initWithView:(N2View*)view controlSize:(NSControlSize)size;
-(void)layOut;

@end
