
#import "sourcesTableView.h"


@implementation sourcesTableView


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	if (!flag) {
		// link for external dragged URLs
		return NSDragOperationLink;
	}
	return [super draggingSourceOperationMaskForLocal:flag];
}

@end