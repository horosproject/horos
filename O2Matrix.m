//
//  O2Matrix.m
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 02.11.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "O2Matrix.h"
#import "DicomStudy.h"

@implementation O2Matrix // we overload NSMatrix, but this class isn't as capable as NSMatrix: we only support 1-column-wide matrixes! so, actually, this isn't a matrix, it's a list, but we still use NSMAtrix so we don't have to modify ViewerController

/*- (void)computeCellRects:(NSRect[])rects maxIndex:(NSInteger)maxIndex {
 
 }*/

- (CGFloat)podCellHeight {
    return self.cellSize.height/2; // this probably will be changed
}

- (void)mouseDown:(NSEvent*)event {
    // whis is where we should check for edit-clicks... but we don't need editing for the preview matrix

//    BOOL act = NO;
    NSEvent* lastMouse = event;

    do {
        NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        NSInteger row, column;
        
        [[self superview] autoscroll:lastMouse];
        [self lockFocus];
        
        if ([self getRow:&row column:&column forPoint:point]) {
            NSCell* cell = [self.cells objectAtIndex:row];
            
            NSRect cellFrame = [self cellFrameAtRow:row column:column];
            int currentState = cell.state;
            int nextState = cell.nextState;
            
            [cell highlight:YES withFrame:cellFrame inView:self];
            
            cell.state = nextState;
            
            [self selectCellAtRow:[self.cells indexOfObjectIdenticalTo:cell] column:0];
            if ([cell trackMouse:lastMouse inRect:cellFrame ofView:self untilMouseUp:NO]) {
                self.keyCell = cell;
                [cell highlight:NO withFrame:cellFrame inView:self];
                [self unlockFocus];
//                act = YES;
                break;
            }
            else {
                [cell setState:currentState];
                [cell highlight:NO withFrame:cellFrame inView:self];
            }
        }
        
        [self unlockFocus];
        [self.window flushWindow];
    
        event = [self.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSPeriodicMask];
        if(event.type != NSPeriodic)
            lastMouse=event;
    } while (lastMouse.type != NSLeftMouseUp);

/*    if (act)
        if (event.clickCount == 2)
            [self sendDoubleAction];
        else [self sendAction];*/
    
    [[self window] flushWindow];
}

- (NSRect)cellFrameAtRow:(NSInteger)row column:(NSInteger)col {
    NSArray* cells = self.cells;
    NSInteger cellsCount = cells.count;
    NSSize cellSize = self.cellSize;
    CGFloat podCellHeight = self.podCellHeight;
    
    NSRect rect = NSMakeRect(0, 0, cellSize.width, 0);
    for (NSInteger i = 0; i < cellsCount; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        id o = [cell representedObject];
        if ([o isKindOfClass:[NSManagedObject class]]) {
            rect.size.height = cellSize.height;
        } else rect.size.height = podCellHeight;
        
        if (i == row)
            return rect;
        
        rect.origin.y += rect.size.height;
        rect.origin.y += self.intercellSpacing.height;
    }

    return NSZeroRect;
}

- (BOOL)getRow:(NSInteger*)row column:(NSInteger*)col forPoint:(NSPoint)aPoint {
    *col = 0;
    
    NSArray* cells = self.cells;
    NSInteger cellsCount = cells.count;
    NSSize cellSize = self.cellSize;
    CGFloat podCellHeight = self.podCellHeight;
    
    NSRect rect = NSMakeRect(0, 0, cellSize.width, 0);
    for (NSInteger i = 0; i < cellsCount; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        id o = [cell representedObject];
        if ([o isKindOfClass:[NSManagedObject class]]) {
            rect.size.height = cellSize.height;
        } else rect.size.height = podCellHeight;
        
        if (NSPointInRect(aPoint, rect)) {
            *row = i;
            return YES;
        }
        
        rect.origin.y += rect.size.height;
        rect.origin.y += self.intercellSpacing.height;
    }

    return NO;
}

//- (void)highlightCell:(BOOL)flag atRow:(NSInteger)row column:(NSInteger)column { // .....
//    if (flag)
//        _highlightedRow = row;
//    else _highlightedRow = -1;
//}

- (void)sizeToCells {
    NSRect r = [self cellFrameAtRow:self.cells.count-1 column:0];
    [self setFrame:NSMakeRect(0, 0, r.origin.x+r.size.width, r.origin.y+r.size.height)];
   // [self.superview setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSArray* cells = self.cells;
    NSInteger cellsCount = cells.count;
    NSSize cellSize = self.cellSize;
    CGFloat podCellHeight = self.podCellHeight;
    
    NSRect rect = NSMakeRect(0, 0, cellSize.width, 0);
    for (NSInteger i = 0; i < cellsCount; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        id o = [cell representedObject];
        if ([o isKindOfClass:[NSManagedObject class]]) {
            rect.size.height = cellSize.height;
        } else rect.size.height = podCellHeight;
        
        [[cells objectAtIndex:i] drawWithFrame:rect inView:self];
//        if (_highlightedRow == i) {
//            [NSGraphicsContext saveGraphicsState];
//            [[[NSColor blackColor] colorWithAlphaComponent:0.5] setFill];
//            [NSBezierPath fillRect:rect];
//            [NSGraphicsContext restoreGraphicsState];
//        }
        
        rect.origin.y += rect.size.height;
        rect.origin.y += self.intercellSpacing.height;
    }
}

@end
