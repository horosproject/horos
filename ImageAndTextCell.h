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


/** \brief Cell that can contain text and and image */

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage	*_myImage, *_lastImage, *_lastImageAlternate;
	BOOL _trackingLastImage, _trackingLastImageMouseIsOnLastImage;
	NSRect _trackingLastImageBounds;
	id _lastImageActionTarget;
	SEL _lastImageActionSelector;
}

//@property(retain) NSImage* image;
@property(retain) NSImage* lastImage;
@property(retain) NSImage* lastImageAlternate;

-(void)setLastImageActionTarget:(id)target selector:(SEL)selector;
-(void)divideCellFrame:(NSRect)cellFrame intoImageFrame:(NSRect*)imageFrame remainingFrame:(NSRect*)restFrame;

@end