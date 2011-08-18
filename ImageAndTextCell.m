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

#import "ImageAndTextCell.h"
#import "N2Debug.h"

@implementation ImageAndTextCell

@synthesize lastImage = _lastImage, lastImageAlternate = _lastImageAlternate;

-(NSImage*)image {
	return _myImage;
}

-(void)setImage:(NSImage*)image {
	if (_myImage != image) {
		[_myImage release];
		_myImage = [image retain];
	}
}

- (NSUInteger) hitTestForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
	if (_lastImage) {
		NSRect cellFrameOut;
		NSDivideRect(cellFrame, &_trackingLastImageBounds, &cellFrameOut, 3 + _lastImage.size.width, NSMaxXEdge);
		if (NSPointInRect([controlView convertPoint:theEvent.locationInWindow fromView:nil], _trackingLastImageBounds)) {
			_trackingLastImage = _trackingLastImageMouseIsOnLastImage = YES;
			[controlView display];
			return NSCellHitTrackableArea;
		}
	}
	
	return [super hitTestForEvent: theEvent inRect: cellFrame ofView: controlView];
}

-(BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
	if (!_trackingLastImage)
		return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];

	BOOL keepOnTracking = YES, wasOnLastImage = _trackingLastImageMouseIsOnLastImage;
	while (keepOnTracking) {
		theEvent = [controlView.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSRightMouseUpMask|NSRightMouseDraggedMask|NSPeriodicMask];
		BOOL isOnLastImage = NSPointInRect([controlView convertPoint:theEvent.locationInWindow fromView:nil], _trackingLastImageBounds);
		_trackingLastImageMouseIsOnLastImage = isOnLastImage;

		switch (theEvent.type) {
			case NSRightMouseDragged:
			case NSLeftMouseDragged: {
				if (isOnLastImage != wasOnLastImage)
					[controlView display];
			} break;
			case NSRightMouseUp:
			case NSLeftMouseUp: {
				keepOnTracking = NO;
			} break;
		}
		
		wasOnLastImage = isOnLastImage;
	}
	
	if (_trackingLastImageMouseIsOnLastImage)
		[_lastImageActionTarget performSelector:_lastImageActionSelector withObject:nil afterDelay:0];
	_trackingLastImage = NO;
	[controlView display];
	
	return YES;
}

- (void)dealloc {
	self.image = nil;
	self.lastImage = nil;
	self.lastImageAlternate = nil;
    [super dealloc];
}

-(id)copyWithZone:(NSZone*)zone {
	ImageAndTextCell* cell = (ImageAndTextCell*)[super copyWithZone:zone];
	if (!cell) return nil;
	cell->_myImage = [_myImage retain];
	cell->_lastImage = [_lastImage retain];
	cell->_lastImageAlternate = [_lastImageAlternate retain];
	[cell setEditable:[self isEditable]];
	return cell;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
//	NSLog(@"Edit ImageAnd TextCell");
    NSRect textFrame, imageFrame;
    [self divideCellFrame:aRect intoImageFrame:&imageFrame remainingFrame:&textFrame];
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect textFrame, imageFrame;
    [self divideCellFrame:aRect intoImageFrame:&imageFrame remainingFrame:&textFrame];
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

-(void)divideCellFrame:(NSRect)cellFrame intoImageFrame:(NSRect*)imageFrame remainingFrame:(NSRect*)restFrame {
    NSSize imageSize = self.image.size;
    NSDivideRect(cellFrame, imageFrame, restFrame, 3 + imageSize.width, NSMinXEdge);
    imageFrame->origin.x += 2;
    imageFrame->size = imageSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrameIn inView:(NSView *)controlView {
	NSRect cellFrame = cellFrameIn;
	
    NSRect imageFrame;
    if (self.image) {
        [self divideCellFrame:cellFrame intoImageFrame:&imageFrame remainingFrame:&cellFrame];

        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [self.image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	NSImage* image = self.lastImage;
	if (_trackingLastImage && _trackingLastImageMouseIsOnLastImage)
		image = _lastImageAlternate;
	
	if (image) {
        NSSize	imageSize;
        NSRect	imageFrame;
		
        imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMaxXEdge);

		imageFrame.origin.x += 3;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (self.image ? self.image.size.width : 0) + 3;
    return cellSize;
}

-(void)setLastImageActionTarget:(id)target selector:(SEL)selector {
	_lastImageActionTarget = target;
	_lastImageActionSelector = selector;
}

@end