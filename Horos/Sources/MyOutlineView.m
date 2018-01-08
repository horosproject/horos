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


#import "MyOutlineView.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "DicomStudy.h"
#import "N2Debug.h"

@implementation MyOutlineView

- (void)removeTableColumn:(NSTableColumn*)tableColumn {
    N2LogStackTrace(@"this is not allowed");
}

- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
	return YES;
}

- (void)keyDown:(NSEvent*)event
{
    if ([[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	 
	if ((c >= 0xF700 && c <= 0xF8FF) || c == 9) // Functions keys, 9 == Tab Key
		[super keyDown:event];
	else
		[[[self window] windowController] keyDown:event];
}

- (NSObject<NSCoding>*)columnState
{
    NSArray* columns = [self tableColumns];
    NSMutableArray* state = [NSMutableArray arrayWithCapacity:[columns count]];

    for (NSTableColumn* column in columns)
        if (![column isHidden])
            [state addObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [column identifier], @"Identifier",
                    [NSNumber numberWithFloat:[column width]], @"Width",
                    nil]];

    return state;
}

- (void)restoreColumnState:(NSArray*)state
{
    NSAssert(state != nil, @"nil columnState!" );
    NSAssert([state isKindOfClass:[NSArray class]], @"columnState is not an NSArray!" );

    [self hideAllColumns];
    for (NSDictionary* params in state )
    {
		if ([[params objectForKey:@"Identifier"] isEqualToString:@"name"] == NO)
		{
			NSTableColumn* column = [self tableColumnWithIdentifier:[params objectForKey:@"Identifier"]];
			if (column != nil)
			{
				[column setHidden:NO];
				[column setWidth:[[params objectForKey:@"Width"] floatValue]];
				[self setIndicatorImage:nil inTableColumn:column];
				[self setNeedsDisplay:YES];
			}
		}
		else
		{
			[[self outlineTableColumn] setWidth:[[params objectForKey:@"Width"] floatValue]];
			[self setNeedsDisplay:YES];
		}
    }

    [self sizeLastColumnToFit];
}

- (void)setColumnWithIdentifier:(id)identifier visible:(BOOL)visible
{
	if ([identifier isEqualToString:@"name"])
        return;

    NSTableColumn* column = [self tableColumnWithIdentifier:identifier];// [self initialColumnWithIdentifier:identifier];
    NSAssert(column != nil, @"nil column!");

    BOOL hidden = !visible;
    
    if (column.isHidden != hidden) {
        [column setHidden:hidden];
        
        if (visible)
            [self moveColumn:[self columnWithIdentifier:identifier] toColumn:1];
        
        [self sizeLastColumnToFit];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)isColumnWithIdentifierVisible:(id)identifier
{
    NSTableColumn* column = [self tableColumnWithIdentifier:identifier];
    return column && !column.isHidden;
}

- (NSTableColumn *)initialColumnWithIdentifier:(id)identifier
{
    return [self tableColumnWithIdentifier:identifier];
}

- (void)hideAllColumns
{
    for (NSTableColumn* column in [self tableColumns])
		if ([[column identifier] isEqualToString:@"name"] == NO)
            [column setHidden:YES];
}

- (void)removeAllColumns // __deprecated
{
    [self hideAllColumns];
}

- (NSArray*)allColumns // __deprecated
{
	return [self tableColumns];
}

- (void)setInitialState // __deprecated
{
    //allColumns = [[NSArray arrayWithArray:[self tableColumns]] retain];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([[sender draggingSource] isEqual:self]) {
		return NSDragOperationNone;
	}
    
    if ([[[BrowserController currentBrowser] database] isReadOnly]) {
		return NSDragOperationNone;
    }
    
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they 
            //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have 
            //to tell them we aren't interested
        
    }
	
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    //we aren't particularily interested in this so we will do nothing
    //this is one of the methods that we do not have to implement
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    
    if ([[[BrowserController currentBrowser] database] isReadOnly]) {
		return NSDragOperationNone;
    }
    
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
                    == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they 
            //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have 
            //to tell them we aren't interested
        return NSDragOperationNone;
    }
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{

}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    
    if ([[[BrowserController currentBrowser] database] isReadOnly]) {
		return NO;
    }
    
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    
    if ([[[BrowserController currentBrowser] database] isReadOnly]) {
		return NO;
    }
    
    if (![[sender draggingSource] isEqual:self])
	{
		NSPasteboard *paste = [sender draggingPasteboard];
		
		NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
		
		NSString *desiredType = [paste availableTypeFromArray:types];
		NSData *carriedData = [paste dataForType:desiredType];
	
		if (nil == carriedData)
		{
//			NSRunAlertPanel(NSLocalizedString(@"Drag Error",nil), NSLocalizedString(@"Sorry, but the past operation failed",nil), 
//            nil, nil, nil);
			return NO;
		}
		else
		{
        //the pasteboard was able to give us some meaningful data
			if ([desiredType isEqualToString:NSFilenamesPboardType])
			{
			return YES;
			}
			else
			{
            //this can't happen
				NSAssert(NO, @"This can't happen");
				return NO;
			}
		}
//		[self setNeedsDisplay:YES];    //redraw us with the new image
//		return YES;
	}
	return NO;
}

- (void) terminateDrag:(NSArray*) fileArray
{
	BOOL	directory;
	BOOL	done = NO;
	
	if( [fileArray count] == 1 && [[NSFileManager defaultManager] fileExistsAtPath: [fileArray objectAtIndex: 0]  isDirectory: &directory])
	{
		if( [[[fileArray objectAtIndex: 0] lastPathComponent] isEqualToString: @"Horos Data"])	// It's a database folder !
		{
			if( [[NSFileManager defaultManager] fileExistsAtPath: [[fileArray objectAtIndex: 0] stringByAppendingPathComponent: @"Database.sql"]])
			{
                [[BrowserController currentBrowser] setDatabase:[DicomDatabase databaseAtPath:[[fileArray objectAtIndex:0] stringByDeletingLastPathComponent]]];
				done = YES;
			}
		}
	}
	
	if( done == NO)
	{
		if( [fileArray count] == 1 && [[[fileArray objectAtIndex: 0] pathExtension] isEqualToString: @"sql"])  // It's a database file !
		{
            [[BrowserController currentBrowser] setDatabase:[DicomDatabase databaseAtPath:[[fileArray objectAtIndex:0] stringByDeletingLastPathComponent]]];
		}
		else if( [fileArray count] == 1 && [[[fileArray objectAtIndex: 0] pathExtension] isEqualToString: @"albums"])  // It's a database albums file !
		{
            
			[[BrowserController currentBrowser] addAlbumsFile: [fileArray objectAtIndex: 0]];
		}
		else
		{
			[[BrowserController currentBrowser] addFilesAndFolderToDatabase:fileArray];
		}
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    if ([[[BrowserController currentBrowser] database] isReadOnly])
		return;
    
    NSPasteboard *paste = [sender draggingPasteboard];
        //gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	//a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
	
    if (nil == carriedData)
    {
//        //the operation failed for some reason
//        NSRunAlertPanel(NSLocalizedString(@"Drag Error",nil), NSLocalizedString(@"Sorry, but the past operation failed",nil), 
//            nil, nil, nil);
        return;
    }
    else
    {
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSFilenamesPboardType])
        {	
			//we have a list of file names in an NSData object
            NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
			
			[self performSelector:@selector(terminateDrag:) withObject:fileArray afterDelay:0.1];
		}
        else
        {
            //this can't happen
            NSAssert(NO, @"This can't happen");
        }
    }
    [self setNeedsDisplay:YES];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery;
    else return NSDragOperationCopy;
}

-(NSMenu*)menuForEvent:(NSEvent*)event
{
	//Find which row is under the cursor
	[[self window] makeFirstResponder:self];
	NSPoint menuPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	int row = [self rowAtPoint:menuPoint];
	
	/* Update the table selection before showing menu
	 Preserves the selection if the row under the mouse is selected (to allow for
	 multiple items to be selected), otherwise selects the row under the mouse */
	BOOL currentRowIsSelected = [[self selectedRowIndexes] containsIndex:row];
	if (!currentRowIsSelected)
		[self selectRowIndexes: [NSIndexSet indexSetWithIndex: row] byExtendingSelection:NO];
	
	if ([self numberOfSelectedRows] <=0)
	{
        //No rows are selected, so the table should be displayed with all items disabled
		NSMenu* tableViewMenu = [[self menu] copy];
		int i;
		for (i=0;i<[tableViewMenu numberOfItems];i++)
			[[tableViewMenu itemAtIndex:i] setEnabled:NO];
		return [tableViewMenu autorelease];
	}
	else
		return [self menu];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[[self window] makeKeyAndOrderFront: self];
	[[self window] makeFirstResponder: self];
	[super rightMouseDown: theEvent];
}

/*- init
{
	self = [super init];
	
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, NSFilenamesPboardType, nil]];
	
	return self;
}*/

/*-(void)resetCursorRects {
	[super resetCursorRects];
	
	
	
}*/

@end
