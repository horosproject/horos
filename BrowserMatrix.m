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

#import "BrowserMatrix.h"
#import "BrowserController.h"
#import "DCMPix.h"

static NSString *albumDragType = @"Osirix Album drag";

@implementation BrowserMatrix

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
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
			
			[self setSelectionFrom:start to:end anchor:start highlight: YES];
			
		}
		else if( [theEvent modifierFlags] & NSCommandKeyMask )
		{
			NSInteger end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			if( [[self selectedCells] containsObject:[self cellAtRow:row column:column]])
				[self setSelectionFrom:end to:end anchor:end highlight: NO];
			else
				[self setSelectionFrom:end to:end anchor:end highlight: YES];

		}
		else
		{
			if( [[self cellAtRow:row column:column] isHighlighted] == NO) [self selectCellAtRow: row column:column];
		}
	}
}

- (void) startDrag:(NSEvent *) event
{
	NSLog( @"startDrag");
	
	NS_DURING
	
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    
	NSPoint event_location = [event locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	local_point.x -= 35;
	local_point.y += 35;
	
	NSArray				*cells = [self selectedCells];
	
	if( [cells count])
	{
		int		i, width = 0;
		NSImage	*firstCell = [[cells objectAtIndex: 0] image];
		
		#define MARGIN 3
		
		width += MARGIN;
		for( i = 0; i < [cells count]; i++)
		{
			width += [[[cells objectAtIndex: i] image] size].width;
			width += MARGIN;
		}
		
		NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( width, 70+6)] autorelease];
		
		[thumbnail lockFocus];
		
		[[NSColor grayColor] set];
		NSRectFill(NSMakeRect(0,0,width, 70+6));
		
		width = 0;
		width += MARGIN;
		for( i = 0; i < [cells count]; i++)
		{
			NSRectFill( NSMakeRect( width, 0, [firstCell size].width, [firstCell size].height));
			
			NSImage	*im = [[cells objectAtIndex: i] image];
			[im drawAtPoint: NSMakePoint(width, 3) fromRect:NSMakeRect(0,0,[im size].width, [im size].height) operation: NSCompositeCopy fraction: 0.8];
		
			width += [im size].width;
		    width += MARGIN;
		}
		[thumbnail unlockFocus];
		
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard]; 
		
		[pboard declareTypes:[NSArray arrayWithObjects:  albumDragType, NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType, nil]  owner:self];
		[pboard setPropertyList:nil forType:albumDragType];
		[pboard setPropertyList:[NSArray arrayWithObject:@"dcm"] forType:NSFilesPromisePboardType];
		
		NSMutableArray	*objects = [NSMutableArray array];
		for( i = 0; i < [cells count]; i++)
		{
			[objects addObject: [[[BrowserController currentBrowser] matrixViewArray] objectAtIndex: [[cells objectAtIndex: i] tag]]];
		}
		[[BrowserController currentBrowser] setDraggedItems: objects];
		
		[self dragImage:thumbnail
				at:local_point
				offset:dragOffset
				event:event 
				pasteboard:pboard 
				source:self 
				slideBack:YES];
	}
	
	NS_HANDLER
		NSLog(@"Exception while dragging: %@", [localException description]);
	NS_ENDHANDLER
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	NSArray *r = nil;
	
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
				NSMutableArray	*dicomFiles2Export = [NSMutableArray array];
				NSMutableArray	 *filesToExport = [[BrowserController currentBrowser] filesForDatabaseMatrixSelection: dicomFiles2Export];
				
				r = [[BrowserController currentBrowser] exportDICOMFileInt: [dropDestination path] files: filesToExport objects: dicomFiles2Export];
			}
		}
		@catch ( NSException * e)
		{
		}
		avoidRecursive = NO;
	}
	
	return r;
}

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationEvery;
}

- (void) startDragOriginalFrame:(NSEvent *) event
{
	[self selectCellEvent: event];
	[[BrowserController currentBrowser] matrixPressed:self];
	NSButtonCell *selectedButtonCell = [[self selectedCells] objectAtIndex: 0];
	NSManagedObject *selectedObject = [[[BrowserController currentBrowser] matrixViewArray] objectAtIndex: [selectedButtonCell tag]];
	if ([[selectedObject valueForKey:@"type"] isEqualToString:@"Image"])
	{
		NS_DURING
		
		NSPoint event_location = [event locationInWindow];
		NSPoint local_point = [self convertPoint:event_location fromView:nil];
		local_point.x -= 35;
		local_point.y += 35;    
		
		NSImage *selectedButtonCellImage = [selectedButtonCell image];
		int	thumbnailWidth = [selectedButtonCellImage size].width + 6;		
		NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( thumbnailWidth, 70+6)] autorelease];		
		[thumbnail lockFocus];		
		[[NSColor grayColor] set];
		NSRectFill(NSMakeRect(0,0,thumbnailWidth, 70+6));		
		NSRectFill( NSMakeRect( 3, 0, [selectedButtonCellImage size].width, [selectedButtonCellImage size].height));			
		[selectedButtonCellImage drawAtPoint: NSMakePoint(3, 3) fromRect:NSMakeRect(0,0,[selectedButtonCellImage size].width, [selectedButtonCellImage size].height) operation: NSCompositeCopy fraction: 0.8];
		[thumbnail unlockFocus];
		
		DCMPix *previewPix = [[BrowserController currentBrowser] previewPix:[selectedButtonCell tag]];
		
		NSString *jpgPath = [NSString stringWithFormat:@"/tmp/%@.%d.jpg",[[selectedObject valueForKeyPath:@"completePath"] lastPathComponent], [[previewPix imageObj] valueForKey:@"frameID"] ];
		if (![[NSFileManager defaultManager] fileExistsAtPath:jpgPath])
		{
			NSArray *representations = [[previewPix image] representations];
			NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			[bitmapData writeToFile:jpgPath atomically:YES];
		}
		
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
		[pboard setPropertyList:[NSArray arrayWithObject:jpgPath] forType:NSFilenamesPboardType];
		[self dragImage:thumbnail
					 at:local_point
				 offset:NSMakeSize(0.0, 0.0)
				  event:event
			 pasteboard:pboard
				 source:self
			  slideBack:YES];
		
		NS_HANDLER
		NSLog(@"Exception while dragging frame: %@", [localException description]);
		NS_ENDHANDLER
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
		
		[NSEvent stopPeriodicEvents];
		[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod:0.001];
		
		NSDate	*start = [NSDate date];
		NSEvent *ev = nil;
		
		do
		{
			ev = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			
			switch ([ev type])
			{
			case NSLeftMouseDragged:
				keepOn = NO;
				break;
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			}
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
}

- (void) rightMouseDown:(NSEvent *)theEvent
{
	[self selectCellEvent: theEvent];
	
	[[BrowserController currentBrowser] matrixPressed: self];
	
	[super rightMouseDown: theEvent];
 }

@end
