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

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    [super drawBezelWithFrame:frame inView:controlView];
    if (self.backgroundColor) {
        [NSGraphicsContext saveGraphicsState];
        [[self.backgroundColor colorWithAlphaComponent:0.75] setFill];
        [NSBezierPath fillRect:NSInsetRect(frame, 1, 1)];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
    return [super drawTitle:title withFrame:NSInsetRect(frame, -2,0) inView:controlView]; // very precioussss 4px/pt
}

@end
