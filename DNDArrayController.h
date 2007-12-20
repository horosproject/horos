
#import <Cocoa/Cocoa.h>
#import <SecurityInterface/SFAuthorizationView.h>


/** \brief Network destination Array Controller for  Q/R*/
@interface DNDArrayController : NSArrayController
{
    IBOutlet NSTableView			*tableView;
	IBOutlet SFAuthorizationView	*_authView;
	
	NSTableColumn *sortedColumn;
}

// table view drag and drop support

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
    
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op;
    
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op;
    

// utility methods

-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet 
				    toIndex:(unsigned)index;

- (NSIndexSet *)indexSetFromRows:(NSArray *)rows;
- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet;
- (void) deleteSelectedRow:(id)sender;
- (NSTableView*) tableView;
@end
