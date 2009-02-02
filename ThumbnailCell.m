#import "ThumbnailCell.h"


@implementation ThumbnailCell

@synthesize rightClick;

- (NSMenu *)menuForEvent:(NSEvent *)anEvent inRect:(NSRect)cellFrame ofView:(NSView *)aView
{
	rightClick = YES;
	
	[self performClick: self];
	
	rightClick = NO;
	
	return nil;
}
@end
