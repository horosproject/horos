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

@class N2Layout;

extern NSString* N2ViewBoundsSizeDidChangeNotification;
extern NSString* N2ViewBoundsSizeDidChangeNotificationOldBoundsSize;

@interface N2View : NSView {
	NSControlSize _controlSize;
	NSSize _minSize, _maxSize;
	N2Layout* _layout;
	NSColor* _foreColor;
	NSColor* _backColor;
}

@property NSControlSize controlSize;
@property NSSize minSize, maxSize;
@property(retain) N2Layout* layout;
@property(nonatomic, retain) NSColor* foreColor;
@property(nonatomic, retain) NSColor* backColor;

-(void)formatSubview:(NSView*)view;
-(void)resizeSubviews;

@end

