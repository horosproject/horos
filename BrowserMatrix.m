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

#import "BrowserMatrix.h"
#import "BrowserController.h"
#import "DCMPix.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "N2Stuff.h"
#import "N2Debug.h"

static NSString *albumDragType = @"Osirix Album drag";

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
	@try {
	
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    
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
		
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard]; 
		
		[pboard declareTypes:[NSArray arrayWithObjects: @"BrowserController.database.context.XIDs", albumDragType, NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType, nil]  owner:self];
		[pboard setPropertyList:nil forType:albumDragType];
		[pboard setPropertyList:[NSArray arrayWithObject:@"dcm"] forType:NSFilesPromisePboardType];

		NSMutableArray* objects = [NSMutableArray array];
		for( i = 0; i < [cells count]; i++)
			[objects addObject:[[[BrowserController currentBrowser] matrixViewArray] objectAtIndex:[[cells objectAtIndex: i] tag]]];
		[pboard setPropertyList:[NSPropertyListSerialization dataFromPropertyList:[objects valueForKey:@"XID"] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL] forType:@"BrowserController.database.context.XIDs"];
		
		[self dragImage:thumbnail
				at:local_point
				offset:dragOffset
				event:event 
				pasteboard:pboard 
				source:self 
				slideBack:YES];
	}
	
	} @catch( NSException *e) {
		N2LogException( e);
	}
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
					if( [[d objectForKey: @"result"] count])
						r = [NSArray arrayWithArray: [d objectForKey: @"result"]];
				}
			}
		}
		@catch ( NSException * e)
		{
            N2LogException( e);
		}
		avoidRecursive = NO;
	}
	
	if( r == nil)
		r = [NSArray array];
	
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
		@try {
		
		NSPoint event_location = [event locationInWindow];
		NSPoint local_point = [self convertPoint:event_location fromView:nil];
		local_point.x -= 35;
		local_point.y += 35;    
		
		NSImage *selectedButtonCellImage = [selectedButtonCell image];
		int	thumbnailWidth = [selectedButtonCellImage size].width + 6;		
		NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( thumbnailWidth, 70+6)] autorelease];
		if( [thumbnail size].width > 0 && [thumbnail size].height > 0)
		{
			[thumbnail lockFocus];		
			[[NSColor grayColor] set];
			NSRectFill(NSMakeRect(0,0,thumbnailWidth, 70+6));		
			NSRectFill( NSMakeRect( 3, 0, [selectedButtonCellImage size].width, [selectedButtonCellImage size].height));			
			[selectedButtonCellImage drawAtPoint: NSMakePoint(3, 3) fromRect:NSMakeRect(0,0,[selectedButtonCellImage size].width, [selectedButtonCellImage size].height) operation: NSCompositeCopy fraction: 0.8];
			[thumbnail unlockFocus];
		}
		DCMPix *previewPix = [[BrowserController currentBrowser] previewPix:[selectedButtonCell tag]];
		
		NSString *jpgPath = [NSString stringWithFormat:@"/tmp/%@.%d.jpg",[[selectedObject valueForKeyPath:@"completePath"] lastPathComponent], [[[previewPix imageObj] valueForKey:@"frameID"] intValue]];
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
