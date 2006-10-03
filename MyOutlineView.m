/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "MyOutlineView.h"
#import "browserController.h"

@implementation MyOutlineView

extern     BrowserController  *browserWindow;


- (NSObject < NSCoding > *)columnState
{
    NSMutableArray    *state;
    NSArray            *columns;
    NSEnumerator    *enumerator;
    NSTableColumn    *column;

    columns = [self tableColumns];
    state = [NSMutableArray arrayWithCapacity:[columns count]];
    enumerator = [columns objectEnumerator];

    while( column = [enumerator nextObject] )
    {
        [state addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                [column identifier], @"Identifier",
                [NSNumber numberWithFloat:[column width]], @"Width",
                nil]];
    }

    return state;
}

- (void)restoreColumnState:(NSObject *)columnState
{
    NSArray                *state;
    NSEnumerator        *enumerator;
    NSDictionary        *params;
    NSTableColumn        *column;

    NSAssert( columnState != nil, @"nil columnState!" );
    NSAssert( [columnState isKindOfClass:[NSArray class]], @"columnState is not an NSArray!" );

    state = (NSArray *)columnState;

    enumerator = [state objectEnumerator];
    [self removeAllColumns];
    while( params = [enumerator nextObject] )
    {
		if( [[params objectForKey:@"Identifier"] isEqualToString:@"name"] == NO)
		{
			column = [self initialColumnWithIdentifier:[params objectForKey:@"Identifier"]];

			if( column != nil )
			{
				[column setWidth:[[params objectForKey:@"Width"] floatValue]];
				[self addTableColumn:column];
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
    NSTableColumn    *column;

	if( [identifier isEqualToString:@"name"]) return;

    column = [self initialColumnWithIdentifier:identifier];

    NSAssert( column != nil, @"nil column!" );

    if( visible )
    {
        if( ![self isColumnWithIdentifierVisible:identifier] )
        {
            [self addTableColumn:column];
            [self sizeLastColumnToFit];
            [self setNeedsDisplay:YES];
        }
    }
    else
    {
        if( [self isColumnWithIdentifierVisible:identifier] )
        {
            [self removeTableColumn:column];
            [self sizeLastColumnToFit];
            [self setNeedsDisplay:YES];
        }
    }
}

- (BOOL)isColumnWithIdentifierVisible:(id)identifier
{
    return [self columnWithIdentifier:identifier] != -1;
}

- (NSTableColumn *)initialColumnWithIdentifier:(id)identifier
{
    NSEnumerator    *enumerator;
    NSTableColumn    *column = nil;

    enumerator = [allColumns objectEnumerator];

    while( column = [enumerator nextObject] )
        if( [[column identifier] isEqual:identifier] )
            break;

    return column;
}

- (void)removeAllColumns
{
    NSArray            *columns;
    NSEnumerator    *enumerator;
    NSTableColumn    *column;

    columns = [NSArray arrayWithArray:[self tableColumns]];
    enumerator = [columns objectEnumerator];

    while( column = [enumerator nextObject] )
	{
		if( [[column identifier] isEqualToString:@"name"] == NO) [self removeTableColumn:column];
	}
}

- (NSArray*) allColumns
{
	return allColumns;
}

- (void)setInitialState
{
    allColumns = [[NSArray arrayWithArray:[self tableColumns]] retain];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([[sender draggingSource] isEqual:self]) {
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
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    //we aren't particularily interested in this so we will do nothing
    //this is one of the methods that we do not have to implement
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
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
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (![[sender draggingSource] isEqual:self])
	{
		NSPasteboard *paste = [sender draggingPasteboard];
		
		NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
		
		NSString *desiredType = [paste availableTypeFromArray:types];
		NSData *carriedData = [paste dataForType:desiredType];
		long	i;
	
		if (nil == carriedData)
		{
			NSRunAlertPanel(NSLocalizedString(@"Drag Error",nil), NSLocalizedString(@"Sorry, but the past operation failed",nil), 
            nil, nil, nil);
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
		[self setNeedsDisplay:YES];    //redraw us with the new image
		return YES;
	}
	return NO;
}

- (void) terminateDrag:(NSArray*) fileArray
{
	long	i;
	
	if( [fileArray count] == 1 && [[[fileArray objectAtIndex: 0] pathExtension] isEqualToString: @"sql"])  // It's a database file!
	{
		[browserWindow openDatabaseIn: [fileArray objectAtIndex: 0] Bonjour:NO];
	}
	else
	{
		NSArray	*newImages = [browserWindow addFilesAndFolderToDatabase: fileArray];
		
		// Are we adding new files in a album?

		//can't add to smart Album
		if( [[browserWindow albumTable] selectedRow] > 0)
		{
			NSManagedObject *album = [[browserWindow albumArray] objectAtIndex: [[browserWindow albumTable] selectedRow]];
			
			if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
			{
				NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
				
				for( i = 0; i < [newImages count]; i++)
				{
					NSManagedObject		*object = [newImages objectAtIndex: i];
					[studies addObject: [object valueForKeyPath:@"series.study"]];
				}
				
				[browserWindow outlineViewRefresh];
			}
		}
		
		if( [newImages count] > 0)
		{
			NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
				
			[self selectRow: [self rowForItem: object] byExtendingSelection: NO];
			[self scrollRowToVisible: [self selectedRow]];
		}
	}
	
	[fileArray release];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
        //gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	//a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
	long	i;
	
    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(NSLocalizedString(@"Drag Error",nil), NSLocalizedString(@"Sorry, but the past operation failed",nil), 
            nil, nil, nil);
        return;
    }
    else
    {
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSFilenamesPboardType])
        {	
			//we have a list of file names in an NSData object
            NSArray				*fileArray = [[paste propertyListForType:@"NSFilenamesPboardType"] retain];
			
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

/*- init
{
	self = [super init];
	
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
	
	return self;
}*/
@end
