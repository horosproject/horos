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

#import "ImageAndTextCell.h"

@implementation ImageAndTextCell

- (NSUInteger) hitTestForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	BOOL clickInButton = NO;
	
	if (lastImage != nil)
	{
		NSPoint pt = [controlView convertPoint:[theEvent locationInWindow] fromView:0L];
		NSSize	imageSize;
		NSRect	imageFrame, cellFrameOut;
			
		imageSize = [lastImage size];
			
		NSDivideRect(cellFrame, &imageFrame, &cellFrameOut, 3 + imageSize.width, NSMaxXEdge);
		
		if( NSMouseInRect( pt, cellFrameOut, NO) == NO)
		{
			if( clickedInLastImage == NO)
			{
				NSImage	*im = lastImage;
				lastImage = lastImageAlternate;
				lastImageAlternate = im;
				
				clickedInLastImage = YES;
				clickInButton = YES;
				
				[controlView display];
			}
			
			while ([theEvent type] != NSLeftMouseUp)
			{
				theEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSMouseEnteredMask | NSMouseExitedMask)];
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"AlternateButtonPressed" object: self];
		}
		else
		{
			if( clickedInLastImage == YES)
			{
				NSImage	*im = lastImage;
				lastImage = lastImageAlternate;
				lastImageAlternate = im;
				
				clickedInLastImage = NO;
				clickInButton = NO;
				
				[controlView display];
			}
		}
	}
	
	return [super hitTestForEvent: theEvent inRect: cellFrame ofView: controlView];
}

- (BOOL) clickedInLastImage
{
	return clickedInLastImage;
}

- (void)dealloc {
    [image release];
	[lastImage release];
	[lastImageAlternate release];
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell->image = [image retain];
	[cell setEditable:[self isEditable]];
    return cell;
}

- (void)setImage:(NSImage *)anImage {
    if (anImage != image) {
        [image release];
        image = [anImage retain];
    }
}

- (void)setLastImage:(NSImage *)anImage {
    if (anImage != lastImage) {
        [lastImage release];
        lastImage = [anImage retain];
    }
}

- (void)setLastImageAlternate:(NSImage *)anImage {
    if (anImage != lastImageAlternate) {
        [lastImageAlternate release];
        lastImageAlternate = [anImage retain];
    }
}

- (NSImage *)image {
    return image;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	NSLog(@"Edit ImageAnd TextCell");
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrameIn inView:(NSView *)controlView {
	
	NSRect cellFrame = cellFrameIn;
	
    if (image != nil)
	{
        NSSize	imageSize;
        NSRect	imageFrame;
		
        imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	if (lastImage != nil)
	{
        NSSize	imageSize;
        NSRect	imageFrame;
		
        imageSize = [lastImage size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMaxXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [lastImage compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
	
	[super drawWithFrame:cellFrame inView:controlView];

}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + 3;
    return cellSize;
}

@end