/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "O2ViewerThumbnailsMatrix.h"
#import "DicomStudy.h"
#import "BrowserController.h"
#import "DicomSeries.h"
#import "ViewerController.h"
#import "AppController.h"
#import "ThumbnailsListPanel.h"
#import "NSThread+N2.h"
#import "N2Stuff.h"
#import "ThreadsManager.h"
#import "N2Debug.h"

@implementation O2ViewerThumbnailsMatrix // we overload NSMatrix, but this class isn't as capable as NSMatrix: we only support 1-column-wide matrixes! so, actually, this isn't a matrix, it's a list, but we still use NSMAtrix so we don't have to modify ViewerController

- (NSRect*)computeCellRectsForCells:(NSArray*)cells maxIndex:(NSInteger)maxIndex {
    NSSize cellSize = self.cellSize;
    
    NSMutableData* rectsmd = [NSMutableData dataWithLength:sizeof(NSRect)*(maxIndex+1)];
    NSRect* rects = (NSRect*)rectsmd.mutableBytes;
    
    NSRect rect = NSMakeRect(0, 0, cellSize.width, 0);
    for (NSInteger i = 0; i <= maxIndex; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        
        rect.size = cell.cellSize;
        
        rects[i] = rect;
        
        rect.origin.y += rect.size.height;
        rect.origin.y += self.intercellSpacing.height;
    }
    
    return rects;
}


- (void) startDrag:(NSEvent *) event
{
	@try
    {
        if( [self selectedCell])
        {
            NSImage	*firstCell = [[self selectedCell] image];
            
#define MARGIN 3
            
            NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( [firstCell size].width + MARGIN*2, [firstCell size].height+MARGIN*2)] autorelease];
            
            if( [thumbnail size].width > 0 && [thumbnail size].height > 0)
            {
                [thumbnail lockFocus];
                
                [[NSColor grayColor] set];
                NSRectFill(NSMakeRect(0,0, [thumbnail size].width, [thumbnail size].height));
                
                [firstCell drawAtPoint: NSMakePoint( MARGIN, MARGIN) fromRect:NSMakeRect(0,0,[firstCell size].width, [firstCell size].height) operation: NSCompositeCopy fraction: 0.8];
                
                [thumbnail unlockFocus];
            }
            
            NSPasteboardItem* pbi = [[[NSPasteboardItem alloc] init] autorelease];
            
            [pbi setPropertyList:[NSPropertyListSerialization dataFromPropertyList:[@[[[[self selectedCell] representedObject] object]] valueForKey:@"XID"] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL] forType:O2PasteboardTypeDatabaseObjectXIDs];

            NSDraggingItem* di = [[[NSDraggingItem alloc] initWithPasteboardWriter:pbi] autorelease];
            NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
            [di setDraggingFrame:NSMakeRect(p.x-thumbnail.size.width/2, p.y-thumbnail.size.height/2, thumbnail.size.width, thumbnail.size.height) contents:thumbnail];
            
            NSDraggingSession* session = [self beginDraggingSessionWithItems:@[di] event:event source:self];
            session.animatesToStartingPositionsOnCancelOrFail = YES;
        }
        
	} @catch( NSException *localException) {
		NSLog(@"Exception while dragging: %@", [localException description]);
	}
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationGeneric;
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    draggingStartingPoint = screenPoint;
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    if( operation == NSDragOperationNone)
    {
        NSWindow *w = [[NSApplication sharedApplication] windowWithWindowNumber: [NSWindow windowNumberAtPoint: screenPoint belowWindowWithWindowNumber:0]];
        
        NSScreen *screen = nil;
        
        for( NSScreen *s in [[AppController sharedAppController] viewerScreens])
        {
            if( NSPointInRect(screenPoint, s.frame))
                screen = s;
        }
        
        NSRect usefulRect = NSMakeRect(0, 0, 0, 0);
        
        if( screen)
            usefulRect = [AppController usefullRectForScreen: screen];
        
        if( fabs( screenPoint.x - draggingStartingPoint.x) > 50 && [w.windowController isKindOfClass: [ThumbnailsListPanel class]] == NO && screen && NSPointInRect( screenPoint, usefulRect))
        {
            ViewerController *newViewer = [[BrowserController currentBrowser] loadSeries :[[[self selectedCell] representedObject] object] :nil :YES keyImagesOnly: NO];
            [newViewer setHighLighted: 1.0];
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
                [NSApp sendAction: @selector(tileWindows:) to:nil from: self];
            else
                [[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
            
            [newViewer.window makeKeyAndOrderFront: self];
        }
    }
}

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationEvery;
}

- (void) actionAndFullscreen: (id) cell
{
    @try
    {
        [[cell target] performSelector: [cell action] withObject: self];
        
        if( [cell action] == @selector(matrixPreviewPressed:))
        {
            ViewerController *v = [cell target];
            [v fullScreenMenu: self];
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
}

- (void)mouseDown:(NSEvent*)event
{
    NSEvent *lastMouse = event;
    NSDate *start = [NSDate date];
    NSCell *previousSelectedCell = nil;
    
#define DRAGTIMEOUT -2
    
    do
    {
        NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        NSInteger row, column;
        
        if ([self getRow:&row column:&column forPoint:point])
        {
            NSCell* cell = [self.cells objectAtIndex:row];
            
            NSRect cellFrame = [self cellFrameAtRow:row column:column];
            int nextState = cell.nextState;
            
            [cell highlight:YES withFrame:cellFrame inView:self];
            
            cell.state = nextState;
            
            [self selectCellAtRow:[self.cells indexOfObjectIdenticalTo:cell] column:0];
            self.keyCell = cell;
            
            if( previousSelectedCell != nil && self.selectedCell != previousSelectedCell)
            {
                [self selectCell: previousSelectedCell];
                start = [NSDate dateWithTimeIntervalSinceNow: DRAGTIMEOUT]; // Force drag
            }
            
            if( previousSelectedCell == nil)
                previousSelectedCell = self.selectedCell;
        }
        else
            start = [NSDate dateWithTimeIntervalSinceNow: DRAGTIMEOUT]; // Force drag
        
        event = [self.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSPeriodicMask];
        
        if(event.type != NSPeriodic)
            lastMouse = event;
    }
    while (lastMouse.type != NSLeftMouseUp && [start timeIntervalSinceNow] >= DRAGTIMEOUT);
    
    id cell = self.selectedCell;
    
    @try {
        
        if( [start timeIntervalSinceNow] < DRAGTIMEOUT && [[[cell representedObject] object] isKindOfClass: [DicomSeries class]])
        {
            [cell setHighlighted: NO];
            [self startDrag: event];
        }
        else
        {
            if( [cell action] && [cell target])
            {
                if( [NSDate timeIntervalSinceReferenceDate] - doubleClick < [NSEvent doubleClickInterval] && doubleClickCell == cell)
                    [self performSelector: @selector( actionAndFullscreen:) withObject: cell afterDelay: 0.001];
                else
                    [[cell target] performSelector: [cell action] withObject: self afterDelay: 0.001];
                
                doubleClick = [NSDate timeIntervalSinceReferenceDate];
                doubleClickCell = cell;
            }
            else
                [cell setHighlighted: NO];
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
}

- (NSRect)cellFrameAtRow:(NSInteger)row column:(NSInteger)col
{
    NSArray* cells = self.cells;
    
    if (row < 0 || row > self.numberOfRows-1)
        return NSZeroRect;
    
    NSRect* rects = [self computeCellRectsForCells:cells maxIndex:row];
    
    return rects[row];
}

- (BOOL)getRow:(NSInteger*)row column:(NSInteger*)col forPoint:(NSPoint)aPoint {
    *col = 0;
    
    NSArray* cells = self.cells;
    NSRect* rects = [self computeCellRectsForCells:cells maxIndex:self.numberOfRows-1];
    
    for (NSInteger i = 0; i < self.numberOfRows; ++i)
        if (NSPointInRect(aPoint, rects[i])) {
            *row = i;
            return YES;
        }
    
    return NO;
}

//- (void)highlightCell:(BOOL)flag atRow:(NSInteger)row column:(NSInteger)column { // .....
//    if (flag)
//        _highlightedRow = row;
//    else _highlightedRow = -1;
//}

- (void)sizeToCells {
    NSRect r = [self cellFrameAtRow:self.numberOfRows-1 column:0];
    [self setFrame:NSMakeRect(0, 0, r.origin.x+r.size.width, r.origin.y+r.size.height)];
   // [self.superview setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSArray* cells = self.cells;
    NSRect* rects = [self computeCellRectsForCells:cells maxIndex:self.numberOfRows-1];
    
    for (NSInteger i = 0; i < self.numberOfRows; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        [cell drawWithFrame:rects[i] inView:self];
    }
}

@end

@implementation O2ViewerThumbnailsMatrixRepresentedObject

@synthesize object = _object;
@synthesize children = _children;

+ (id)object:(id)object {
    return [self object:object children:nil];
}

+ (id)object:(id)object children:(NSArray*)children {
    O2ViewerThumbnailsMatrixRepresentedObject* oro = [[[[self class] alloc] init] autorelease];
    oro.object = object;
    oro.children = [[children copy] autorelease];
    return oro;
}

- (void)dealloc {
    self.object = nil;
    self.children = nil;
    [super dealloc];
}

@end


