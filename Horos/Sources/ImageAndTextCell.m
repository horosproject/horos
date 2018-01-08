/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "ImageAndTextCell.h"
#import "BrowserController.h"
#import "N2Debug.h"

@implementation ImageAndTextCell

- (NSCellHitResult)hitTestForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	if (lastImage != nil)
	{
		NSPoint pt = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
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
				
				[controlView display];
			}
			
            [[BrowserController currentBrowser] alternateButtonPressed: nil];
		}
		else
		{
			if( clickedInLastImage == YES)
			{
				NSImage	*im = lastImage;
				lastImage = lastImageAlternate;
				lastImageAlternate = im;
				
				clickedInLastImage = NO;
				
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
	if( cell == nil) return nil;
    
    cell->image = [image retain];
    cell->lastImage = [lastImage retain];
    cell->lastImageAlternate = [lastImageAlternate retain];
    
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

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrameIn inView:(NSView *)controlView {
	NSRect cellFrame = cellFrameIn;
    
    @try {
	
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
        
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        
        [image drawAtPoint:imageFrame.origin fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
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
        
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        
        [lastImage drawAtPoint:imageFrame.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
	}

    } @catch( NSException *localException) {
    N2LogExceptionWithStackTrace(localException);
    }
	
	[super drawWithFrame:cellFrame inView:controlView];
    
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + 3;
    return cellSize;
}

@end
