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

#import "DragMatrix.h"
#import "Notifications.h"

float INS_WIDTH = 2;
float CIRCLE_SIZE = 6;
NSString *pasteBoardTypeCover = @"KeyImages";
        
/*****************************************************************************
 * Function - _scaledImage
 *
 * HACK.  This is used to access the scaled image of a imageCell.
 * When the user drags the image we want the scaled image not the full
 * size.
*****************************************************************************/
@implementation NSImageCell(DraggableImageView)
- (NSImage *)_scaledImage {
    return _scaledImage;
}
@end

@implementation DragMatrix

/*****************************************************************************
 * Function - initWithCoder
 *
 * Initialize and register ourself for drag operation.  Note since we use
 * a private user defined drag type (pasteBoardTypeCover) we will only
 * accept drags from within this app. This is called when we've been loaded
 * from an NIB.
*****************************************************************************/
- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
	{
        [self registerForDraggedTypes:[NSArray arrayWithObjects:pasteBoardTypeCover, nil]];
    }
    return self;
}
 
/*****************************************************************************
 * Function - initWithFrame
 *
 * Initialize and register ourself for drag operation.  Note since we use
 * a private user defined drag type (pasteBoardTypeCover) we will only
 * accept drags from within this app.  This is called when we've been created
 * dynamically (as opposed to loaded from a NIB).
*****************************************************************************/
- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:pasteBoardTypeCover, nil]];
    }
    return self;
}



/*****************************************************************************
 * Function - clearDragDestinationMembers
 *
 * Resets all member variables used by DragDestination functions.
*****************************************************************************/
- (void) clearDragDestinationMembers {
    shouldDraw = FALSE;
    oldDrawRect = NSZeroRect;
    newDrawRect = NSZeroRect;
}

/*****************************************************************************
 * Function - draggingEntered (implements NSDraggingDestination)
 *
 * Called when the user drags an object on top of us. The return value tells
 * the caller if we'll accept the object.
*****************************************************************************/
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{ 
	[self clearDragDestinationMembers];
    if ([sender draggingSource] == self)
	{
		return NSDragOperationNone;
    }
	else
	{
		return NSDragOperationEvery;
    }
}

/*****************************************************************************
 * Function - prepareDragOperation (implements NSDraggingDestination)
 *
 *
 *
***************************************************************************/
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender{
	return YES;
}

/*****************************************************************************
 * Function - performDragOperation (implements NSDraggingDestination)
 *
 * Called after the user releases the drag object.  Here we perform the
 * result of the dragging.
*****************************************************************************/
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if ([sender draggingSource] == self)
		return NO;
	
    NSPasteboard *pboard;
    NSArray *types;
    pboard = [sender draggingPasteboard];
    types = [pboard types];
    if ([types indexOfObject:pasteBoardTypeCover] != NSNotFound)
	{
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		NSDictionary *dict;
		//[arrayController setSelectedObjects:[NSArray arrayWithObject:[[arrayController content] objectAtIndex:srcCol]]];
		NSArray *array = [[sender draggingSource] selection];
		//NSLog(@"Selection: 
        dict = [NSDictionary dictionaryWithObject:array forKey:@"images"];
        [nc postNotificationName:OsirixDragMatrixImageMovedNotification object:self userInfo:dict];
    }
	
    
    [self clearDragDestinationMembers];
    [self setNeedsDisplay:TRUE];
    
    return YES;
}

/*****************************************************************************
 * Function - draggingExited (implements NSDraggingDestination)
 *
 * Invoked when the dragged image exits the destination's bounds rectangle.
 * We use this to erase the insertion pointer from the view.
*****************************************************************************/
- (void)draggingExited:(id <NSDraggingInfo>)sender {
    [self clearDragDestinationMembers];
    [self setNeedsDisplay:TRUE];
}

/*****************************************************************************
 * Function - draggingUpdated (implements NSDraggingDestination)
 *
 * Invoked periodically as the image is held within the destination.
 * The messages continue until the image is either released or dragged out of
 * the window or view.
 *
 * To give the user feedback about where the image will be droped we
 * draw a little insertion point.
*****************************************************************************/
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPoint point;
    NSSize cellSize, cellSpacing;
    NSRect drawRect, cellRect;;
    int row, column;
    float offsetx;

    if ([sender draggingSource] == self)
        return NSDragOperationNone;
    
    // Note that the matrix coordiante system is flipped such that the
    // origin is located on the top left (as opposed to bottom left).
    point = [self convertPoint:[sender draggingLocation] fromView:nil];

    cellSize = [self cellSize];
    cellSpacing = [self intercellSpacing];

    if (point.y < cellSize.height) {
        row = 0; 
    } else {
        row = (point.y-cellSize.height)/(cellSize.height+cellSpacing.height) + 1;
    }
    if (point.x < cellSize.width) {
        column = 0;
    } else {
        column = (point.x-cellSize.width)/(cellSize.width+cellSpacing.width) + 1;
    }

    cellRect = [self cellFrameAtRow:row column:column];
    offsetx = cellSpacing.width/2 - INS_WIDTH/2;
    drawRect.size.height = cellRect.size.height;
    drawRect.size.width = INS_WIDTH;
    drawRect.origin.y = cellRect.origin.y;
    if (point.x < cellRect.origin.x + cellSize.width/2) {
        // insert to the left
        if (column == 0) {
            drawRect.origin.x = cellRect.origin.x;
        } else {
            // HACK - I just nudge it 2 pixels to the left to make it
            // centered.  I have no idea what the correct way to do this is
            drawRect.origin.x = cellRect.origin.x - offsetx - 2;
        }
        dstCol = column;
    } else {
        // insert to the right
        if (column == [self numberOfColumns] - 1) {
            drawRect.origin.x = cellRect.origin.x + cellRect.size.width - 2;
        } else {
            drawRect.origin.x = cellRect.origin.x + cellRect.size.width + offsetx;
        }
        dstCol = column+1;
    }

    shouldDraw = TRUE;
    dstRow = row;
    
    // Don't ask the view to draw it self unless necessary
    if (NSEqualRects(drawRect, oldDrawRect) == FALSE) {
        newDrawRect = drawRect;
        [self setNeedsDisplay:TRUE];
    }

    return NSDragOperationAll;   
}

/*****************************************************************************
 * Function - drawRect
 *
 * We override drawRect so we can draw our insertion pointer to indicate where
 * the drag will occur.
*****************************************************************************/
- (void) drawRect:(NSRect)rect {
    [super drawRect:rect];
    if (shouldDraw) {
        NSRect rect;
        
        shouldDraw = TRUE;
        [[NSColor blackColor] set];
        [NSBezierPath fillRect:newDrawRect];
        
        rect.size.width = CIRCLE_SIZE;
        rect.size.height = CIRCLE_SIZE;
        rect.origin.x = newDrawRect.origin.x + INS_WIDTH/2 - CIRCLE_SIZE/2;
        rect.origin.y = newDrawRect.origin.y - CIRCLE_SIZE;
        [[NSBezierPath bezierPathWithOvalInRect:rect] stroke];
        
        oldDrawRect = newDrawRect;
    }
}

/*****************************************************************************
 * Function - startDrag
 *
 * Private function.  We use this to start the drag operation.
*****************************************************************************/
- (void)startDrag:(NSEvent *)event { 
    NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSDragPboard]; 
    NSImage *scaledImage, *dragImage;
    NSSize size; 
    NSPoint dragPoint, pt; 
    NSRect theDraggedCellFrame; 
    
    pt = [self convertPoint:[event locationInWindow] fromView:nil];
    [self getRow:&srcRow column:&srcCol forPoint:pt]; 
    // Note: _scaledImage is function we add to NSImageCell in our category.
    //scaledImage = [[self cellAtRow:srcRow column:srcCol] _scaledImage]; 
    scaledImage = [[self cellAtRow:srcRow column:srcCol] image]; 
	[self selectCellAtRow:srcRow column:srcCol];
	[arrayController setSelectionIndex:srcCol];
	//[arrayController setSelectedObjects:[NSArray arrayWithObject:[[arrayController content] objectAtIndex:srcCol]]];
    theDraggedCellFrame = [self cellFrameAtRow:srcRow column:srcCol]; 
    size = [scaledImage size];
    dragPoint.x = theDraggedCellFrame.origin.x 
        + ([self cellSize].width - size.width) / 2;
    dragPoint.y = theDraggedCellFrame.origin.y + size.height
        + ([self cellSize].height - size.height) / 2;

    [pb declareTypes: [NSArray arrayWithObjects: pasteBoardTypeCover, nil] owner: self]; 
    [pb setData:nil forType:pasteBoardTypeCover]; 

    // we want to make the image a little bit transparent so the user can see where
    // they're dragging to
    dragImage = [[[NSImage alloc] initWithSize: [scaledImage size]] autorelease];
	
	if( [dragImage size].width > 0 && [dragImage size].height > 0)
	{
		[dragImage lockFocus]; 
		[scaledImage dissolveToPoint: NSMakePoint(0,0) fraction: .5]; 
		[dragImage unlockFocus]; 
	}
	
    [self dragImage: dragImage 
                 at: dragPoint 
             offset: NSMakeSize(0,0) 
              event: event 
         pasteboard: pb 
             source: self 
          slideBack: YES]; 
}


/*****************************************************************************
 * Function - shouldDelayWindowOrderingForEvent:
 *
 * Private function.  We use this to start the drag operation.
*****************************************************************************/
- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)event { 
    // maybe make more discerning?! 
    return YES; 
} 

/*****************************************************************************
 * Function - acceptsFirstMouse:
 *
 * Private function.  We use this to start the drag operation.
*****************************************************************************/
- (BOOL)acceptsFirstMouse:(NSEvent *)event { 
    return YES; 
} 

/*****************************************************************************
 * Function - mouseDown:
 *
 * Private function.  We use this to start the drag operation.
*****************************************************************************/
- (void)mouseDown:(NSEvent *)event { 
    [self setDownEvent:event];
}

/*****************************************************************************
 * Function - mouseUp:
 *
 * Private function.  We use this to start the drag operation.
*****************************************************************************/
- (void)mouseUp:(NSEvent *)event {
    BOOL cellWasHit;
    NSInteger row, column;
    NSPoint point;
    
    point = [self convertPoint:[event locationInWindow] fromView:nil];
    cellWasHit = [self getRow:&row column:&column forPoint:point];
    if (!cellWasHit) {
        [super mouseUp:event];
        return;
    }
    
    if ([event modifierFlags] & NSCommandKeyMask) {
        int r,c, s, i, i2;
        r = [self selectedRow];
        c = [self selectedColumn];
        s = [self numberOfColumns];
        i = r*s + c;
        i2 = row*s + column;
        [self setSelectionFrom:i2 to:i2 anchor:i2 highlight:YES];     
    } else if ([event modifierFlags] & NSShiftKeyMask) {
        int r,c, s, i, i2;
        r = [self selectedRow];
        c = [self selectedColumn];
        s = [self numberOfColumns];
        i = r*s + c;
        i2 = row*s + column;
        [self setSelectionFrom:i to:i2 anchor:i highlight:YES];
    } else {
        [self selectCellAtRow:row column:column];
    }
}

/*****************************************************************************
 * Function - mouseDragged:
 *
 * If we hit a cell, then start the drag 
*****************************************************************************/
- (void)mouseDragged:(NSEvent *)event { 
    NSInteger row, column; 
    NSPoint point;

    point = [self convertPoint:[event locationInWindow] fromView:nil];
    if ([self getRow:&row column:&column forPoint:point]) { 
        [self startDrag:downEvent]; 
    } 
    [self setDownEvent:nil]; 
} 

/*****************************************************************************
 * Function - downEvent
 *
 * Return the mouse down event.
*****************************************************************************/
- (NSEvent *)downEvent { 
    return downEvent; 
} 

/*****************************************************************************
 * Function - setDownEvent:
 *
 * Set the mouse down event.
*****************************************************************************/
- (void)setDownEvent:(NSEvent *)event { 
    [downEvent autorelease]; 
    downEvent = [event retain]; 
} 


-(NSArray *)selection{
	return [arrayController selectedObjects];
}





@end
