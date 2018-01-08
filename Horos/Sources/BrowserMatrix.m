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

#import "BrowserMatrix.h"
#import "BrowserController.h"
#import "DCMPix.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "N2Stuff.h"
#import "N2Debug.h"
#import "DicomImage.h"

@implementation BrowserMatrix

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (id) selectedCell
{
	NSButtonCell *s = [super selectedCell];
	
	if( [s isTransparent])
	{
		for( NSButtonCell *c in [super selectedCells])
		{
			if( [c isTransparent] == NO)
				return c;
		}
	}
	
	return s;
}

- (NSArray*) selectedCells
{
	NSMutableArray *m = [NSMutableArray arrayWithArray: [super selectedCells]];
	NSMutableArray *r = [NSMutableArray arrayWithCapacity: [m count]];
	
	for( NSButtonCell *c in m)
	{
		if( [c isTransparent] == NO)
			[r addObject: c];
	}
	
	return r;
} 

- (void) selectCellEvent:(NSEvent*) theEvent
{
	NSInteger row, column;
 
	if( [self getRow: &row column: &column forPoint: [self convertPoint:[theEvent locationInWindow] fromView:nil]])
	{
		if( [theEvent modifierFlags] & NSShiftKeyMask )
		{
			NSInteger start = [[self cells] indexOfObject: [[self selectedCells] objectAtIndex: 0]];
			NSInteger end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			[self setSelectionFrom:start to:end anchor:start highlight: NO];
			
		}
		else if( [theEvent modifierFlags] & NSCommandKeyMask )
		{
			NSInteger end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			if( [[self selectedCells] containsObject:[self cellAtRow:row column:column]])
				[self setSelectionFrom:end to:end anchor:end highlight: NO];
			else
				[self setSelectionFrom:end to:end anchor:end highlight: NO];

		}
		else
		{
			if( [[self cellAtRow:row column:column] isHighlighted] == NO) [self selectCellAtRow: row column:column];
		}
	}
}

- (void) startDrag:(NSEvent *) event
{
	@try {
	
	NSPoint event_location = [event locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	local_point.x -= 35;
	local_point.y += 35;
	
	NSArray *cells = [self selectedCells];
	
	if( [cells count])
	{
        NSArray *subArray = cells;
        
        if( subArray.count > 20)
            subArray = [cells subarrayWithRange: NSMakeRange( 0, 20)];
        
		int i, width = 0;
		NSImage	*firstCell = [[subArray objectAtIndex: 0] image];
		
		#define MARGIN 3
		
		width += MARGIN;
		for( i = 0; i < [subArray count]; i++)
		{
			width += [[[subArray objectAtIndex: i] image] size].width;
			width += MARGIN;
		}
		
		NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( width, 70+6)] autorelease];
		
		if( [thumbnail size].width > 0 && [thumbnail size].height > 0)
		{
			[thumbnail lockFocus];
			
			[[NSColor grayColor] set];
			NSRectFill(NSMakeRect(0,0,width, 70+6));
			
			width = 0;
			width += MARGIN;
			for( i = 0; i < [subArray count]; i++)
			{
				NSRectFill( NSMakeRect( width, 0, [firstCell size].width, [firstCell size].height));
				
				NSImage	*im = [[subArray objectAtIndex: i] image];
				[im drawAtPoint: NSMakePoint(width, 3) fromRect:NSMakeRect(0,0,[im size].width, [im size].height) operation: NSCompositeCopy fraction: 0.8];
			
				width += [im size].width;
				width += MARGIN;
			}
			[thumbnail unlockFocus];
		}
		
        NSPasteboardItem* pbi = [[[NSPasteboardItem alloc] init] autorelease];
        [pbi setDataProvider:self forTypes:@[NSPasteboardTypeString, (NSString *)kPasteboardTypeFileURLPromise]];
        [pbi setString:(id)kUTTypeImage forType:(id)kPasteboardTypeFilePromiseContent];
        
        NSMutableArray* objects = [NSMutableArray array];
        for( i = 0; i < [cells count]; i++)
            [objects addObject:[[[BrowserController currentBrowser] matrixViewArray] objectAtIndex:[[cells objectAtIndex: i] tag]]];
        [pbi setPropertyList:[NSPropertyListSerialization dataFromPropertyList:[objects valueForKey:@"XID"] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL] forType:O2PasteboardTypeDatabaseObjectXIDs];
        
        NSDraggingItem* di = [[[NSDraggingItem alloc] initWithPasteboardWriter:pbi] autorelease];
        NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
        [di setDraggingFrame:NSMakeRect(p.x-thumbnail.size.width/2, p.y-thumbnail.size.height/2, thumbnail.size.width, thumbnail.size.height) contents:thumbnail];
        
        NSDraggingSession* session = [self beginDraggingSessionWithItems:@[di] event:event source:self];
        session.animatesToStartingPositionsOnCancelOrFail = YES;
	}
	
	} @catch( NSException *e) {
		N2LogException( e);
	}
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationGeneric;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    if ([type isEqualToString:(id)kPasteboardTypeFileURLPromise]) {
        PasteboardRef pboardRef = NULL;
        PasteboardCreate((__bridge CFStringRef)[pasteboard name], &pboardRef);
        if (!pboardRef)
            return;
        
        PasteboardSynchronize(pboardRef);
        
        CFURLRef urlRef = NULL;
        PasteboardCopyPasteLocation(pboardRef, &urlRef);
        
        if (urlRef) {
            NSURL *dropDestination = (id)urlRef;
            
            // this method provides data for drags initiated both from startDrag: and startDragOriginalFrame:
            // to distinguish, we know that only the startDrag: initiated drags provide a value for O2PasteboardTypeDatabaseObjectXIDs
            
            if ([item availableTypeFromArray:@[O2PasteboardTypeDatabaseObjectXIDs]]) { // this is from startDrag:
                if( avoidRecursive == NO)
                {
                    avoidRecursive = YES;
                    
                    @try
                    {
                        if( [[[dropDestination path] lastPathComponent] isEqualToString:@".Trash"])
                        {
                            [[BrowserController currentBrowser] delItem: [[[[BrowserController currentBrowser] oMatrix] menu] itemAtIndex: 0]];
                        }
                        else
                        {
                            NSMutableArray *dicomFiles2Export = [NSMutableArray array];
                            NSMutableArray *filesToExport = [[BrowserController currentBrowser] filesForDatabaseMatrixSelection: dicomFiles2Export];
                            
                            //				r = [[BrowserController currentBrowser] exportDICOMFileInt: [dropDestination path] files: filesToExport objects: dicomFiles2Export];
                            
                            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys: [dropDestination path], @"location", filesToExport, @"filesToExport", [dicomFiles2Export valueForKey: @"objectID"], @"dicomFiles2Export", nil];
                            
                            NSThread* t = [[[NSThread alloc] initWithTarget:[BrowserController currentBrowser] selector:@selector(exportDICOMFileInt: ) object: d] autorelease];
                            t.name = NSLocalizedString( @"Exporting...", nil);
                            t.supportsCancel = YES;
                            t.status = N2LocalizedSingularPluralCount( [filesToExport count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
                            
                            [[ThreadsManager defaultManager] addThreadAndStart: t];
                            
                            NSTimeInterval fourSeconds = [NSDate timeIntervalSinceReferenceDate] + 4.0;
                            while( [[d objectForKey: @"result"] count] == 0 && [NSDate timeIntervalSinceReferenceDate] < fourSeconds)
                                [NSThread sleepForTimeInterval: 0.1];
                            
                            @synchronized( d)
                            {
                                if ([[d objectForKey:@"result"] count]) {
                                    [item setPropertyList:[[NSSet setWithArray:[d objectForKey:@"result"]] allObjects] forType:type];
                                }
                            }
                        }
                    }
                    @catch ( NSException * e)
                    {
                        N2LogException( e);
                    }
                    avoidRecursive = NO;
                }
            }
            else { // this is from startDragOriginalFrame:
                NSButtonCell *selectedButtonCell = [[self selectedCells] objectAtIndex: 0];
                DicomImage *selectedObject = [[[BrowserController currentBrowser] matrixViewArray] objectAtIndex: [selectedButtonCell tag]];
                DCMPix *previewPix = [[BrowserController currentBrowser] previewPix:[selectedButtonCell tag]];
                
                NSURL *url = [dropDestination URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%d.jpg", selectedObject.completePath.lastPathComponent, previewPix.imageObj.frameID.intValue]];
                size_t i = 0;
                while ([url checkResourceIsReachableAndReturnError:NULL])
                    url = [dropDestination URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%d (%lu).jpg", selectedObject.completePath.lastPathComponent, previewPix.imageObj.frameID.intValue, i]];

                NSArray *representations = [[previewPix image] representations];
                NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
                [bitmapData writeToURL:url atomically:YES];
                
                [item setString:[url absoluteString] forType:type];
            }
            
            CFRelease(urlRef);
        }
        
        CFRelease(pboardRef);
    }
}

- (void) startDragOriginalFrame:(NSEvent *) event
{
	[self selectCellEvent: event];
	[[BrowserController currentBrowser] matrixPressed:self];
	NSButtonCell *selectedButtonCell = [[self selectedCells] objectAtIndex: 0];
	NSManagedObject *selectedObject = [[[BrowserController currentBrowser] matrixViewArray] objectAtIndex: [selectedButtonCell tag]];
	if ([[selectedObject valueForKey:@"type"] isEqualToString:@"Image"])
	{
		@try {
            NSImage *image = [selectedButtonCell image];
            int	thumbnailWidth = [image size].width + 6;
            NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( thumbnailWidth, 70+6)] autorelease];
            if ([thumbnail size].width > 0 && [thumbnail size].height > 0) {
                [thumbnail lockFocus];		
                [[NSColor grayColor] set];
                NSRectFill(NSMakeRect(0,0,thumbnailWidth, 70+6));		
                NSRectFill( NSMakeRect( 3, 0, [image size].width, [image size].height));
                [image drawAtPoint: NSMakePoint(3, 3) fromRect:NSMakeRect(0,0,[image size].width, [image size].height) operation: NSCompositeCopy fraction: 0.8];
                [thumbnail unlockFocus];
            }
		
            NSPasteboardItem* pbi = [[[NSPasteboardItem alloc] init] autorelease];
            [pbi setDataProvider:self forTypes:@[NSPasteboardTypeString, (NSString *)kPasteboardTypeFileURLPromise]];
            [pbi setString:(id)kUTTypeImage forType:(id)kPasteboardTypeFilePromiseContent];
            
            NSDraggingItem* di = [[[NSDraggingItem alloc] initWithPasteboardWriter:pbi] autorelease];
            NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
            [di setDraggingFrame:NSMakeRect(p.x-thumbnail.size.width/2, p.y-thumbnail.size.height/2, thumbnail.size.width, thumbnail.size.height) contents:thumbnail];
            
            NSDraggingSession* session = [self beginDraggingSessionWithItems:@[di] event:event source:self];
            session.animatesToStartingPositionsOnCancelOrFail = YES;
		
		} @catch( NSException *e) {
            N2LogException( e);
		}
	}
}

- (void) mouseDown:(NSEvent *)event
{
	if(([event modifierFlags]  & NSAlternateKeyMask) && ([event modifierFlags] & NSShiftKeyMask))
	{
		[self startDragOriginalFrame: event];
	}
	else if ([event modifierFlags]  & NSAlternateKeyMask)
	{
		[self startDrag: event];
	}
	else
	{		
		BOOL keepOn = YES;
		
		@try
		{
			[NSEvent stopPeriodicEvents];
			[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod:0.001];
		}
		@catch (NSException *e)
		{
			N2LogException( e);
		}
		NSDate	*start = [NSDate date];
		NSEvent *ev = nil;
		
        @try
		{
		do
		{
			ev = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			if (ev.type == NSLeftMouseDragged || ev.type == NSLeftMouseUp)
				keepOn = NO;
		}while (keepOn && [start timeIntervalSinceNow] >= -1);
		
		if( keepOn)
		{
			[self selectCellEvent: event];
			[self startDrag: event];
		}
		else
		{
			[super mouseDown: ev];
		}
		
		[NSEvent stopPeriodicEvents];
        }
        @catch ( NSException *e) {
            N2LogException( e);
        }
	}
	
	[self.window makeFirstResponder: self];
}

- (void) rightMouseDown:(NSEvent *)theEvent
{
	[self selectCellEvent: theEvent];
	
	[[BrowserController currentBrowser] matrixPressed: self];
	
	[super rightMouseDown: theEvent];
 }

@end
