//
//  O2Matrix.m
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 02.11.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "O2Matrix.h"
#import "DicomStudy.h"

@implementation O2Matrix
/*
- (void)mouseDown:(NSEvent*)event {
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger row, column;
    BOOL act = NO;
    












}

- (CGFloat)podCellHeight {
    return self.cellSize.height/2;
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
*/
@end
