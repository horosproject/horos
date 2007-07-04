
#import "DNDArrayController.h"

NSString *MovedRowsType = @"MOVED_ROWS_TYPE";
NSString *CopiedRowsType = @"COPIED_ROWS_TYPE";

@implementation DNDArrayController

- (NSTableView*) tableView
{
	return tableView;
}

- (void)addObject:(id)object
{
	[super addObject: object];
	[tableView selectRow: [[self arrangedObjects] count]-1 byExtendingSelection: NO];
}

- (void) setAuthView:( SFAuthorizationView*) v;
{
	_authView = v;
}

- (void) deleteSelectedRow:(id)sender
{
	if( _authView == 0L || [_authView authorizationState] == SFAuthorizationViewUnlockedState)
	{
		if( NSRunInformationalAlertPanel(NSLocalizedString(@"Delete Server", 0L), NSLocalizedString(@"Are you sure you want to delete the selected item?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil) == NSAlertDefaultReturn)
		{
			[self removeObjectAtArrangedObjectIndex: [tableView selectedRow]];
		}
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self arrangedObjects] count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [[aTableColumn identifier] isEqual:@"name"] == YES)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [[self arrangedObjects] count]);
		
		NSMutableDictionary *theRecord = [[self arrangedObjects] objectAtIndex:rowIndex];
		
		switch( [[theRecord objectForKey:@"test"] intValue])
		{
			case -1:
				[aCell setTextColor: [NSColor orangeColor]];
			break;
			
			case -2:
				[aCell setTextColor: [NSColor redColor]];
			break;
			
			case 0:
				[aCell setTextColor: [NSColor blackColor]];
			break;
		}
	}
}

- (void)awakeFromNib
{
    // register for drag and drop
    [tableView registerForDraggedTypes: [NSArray arrayWithObjects:MovedRowsType, nil]];
//    [tableView setAllowsMultipleSelection:YES];
	[super awakeFromNib];
}



- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard
{
	if( _authView != 0L)
	{
		if( [_authView authorizationState] != SFAuthorizationViewUnlockedState)
		{
			return NO;
		}
	}

	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:MovedRowsType, nil];
	
	[pboard declareTypes:typesArray owner:self];
	
	
    // add rows array for local move
    [pboard setPropertyList:rows forType:MovedRowsType];
	
	// create new array of selected rows for remote drop
    // could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rows count]];    
	NSEnumerator *rowEnumerator = [rows objectEnumerator];
	NSNumber *idx;
	while (idx = [rowEnumerator nextObject]) {
		[rowCopies addObject:[[self arrangedObjects] objectAtIndex:[idx intValue]]];
		[tableView selectRow: [idx intValue] byExtendingSelection: NO];
	}
	// setPropertyList works here because we're using dictionaries, strings,
	// and dates; otherwise, archive collection to NSData...
	[pboard setPropertyList:rowCopies forType:CopiedRowsType];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{

	if( _authView != 0L)
	{
		if( [_authView authorizationState] != SFAuthorizationViewUnlockedState)
		{
			return NSDragOperationNone;
		}
	}
	
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView) {
		dragOp =  NSDragOperationMove;
    }
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( _authView)
	{
		if( [_authView authorizationState] != SFAuthorizationViewUnlockedState) return NO;
	}
	
	return YES;
}

- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
	if( _authView != 0L)
	{
		if( [_authView authorizationState] != SFAuthorizationViewUnlockedState)
		{
			return NO;
		}
	}
	
    if (row < 0) {
		row = 0;
	}
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView) {
		
		NSArray *rows = [[info draggingPasteboard] propertyListForType:MovedRowsType];
		NSIndexSet  *indexSet = [self indexSetFromRows:rows];
		
		[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		
		// set selected rows to those that were just moved
		// Need to work out what moved where to determine proper selection...
		int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
		
		NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
		indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[self setSelectionIndexes:indexSet];
		
		return YES;
    }
    return NO;
}



-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(unsigned int)insertIndex
{
	
    NSArray		*objects = [self arrangedObjects];
	int			index = [indexSet lastIndex];
	
    int			aboveInsertIndexCount = 0;
    id			object;
    int			removeIndex;
	
    while (NSNotFound != index) {
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else {
			removeIndex = index;
			insertIndex -= 1;
		}
		object = [objects objectAtIndex:removeIndex];
		[self removeObjectAtArrangedObjectIndex:removeIndex];
		[self insertObject:object atArrangedObjectIndex:insertIndex];
		
		[tableView selectRow: insertIndex byExtendingSelection: NO];
		
		index = [indexSet indexLessThanIndex:index];
    }
}


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *rowEnumerator = [rows objectEnumerator];
    NSNumber *idx;
    while (idx = [rowEnumerator nextObject]) {
		[indexSet addIndex:[idx intValue]];
    }
    return indexSet;
}


- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet
{
    unsigned currentIndex = [indexSet firstIndex];
    int i = 0;
    while (currentIndex != NSNotFound) {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}

@end
