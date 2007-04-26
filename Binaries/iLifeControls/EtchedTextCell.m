#import "EtchedTextCell.h"

@implementation EtchedTextCell

-(void)setShadowColor:(NSColor *)color
{
	mShadowColor = [color retain];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(id)controlView
{
	[NSGraphicsContext saveGraphicsState]; 
	NSShadow* theShadow = [[NSShadow alloc] init]; 
	[theShadow setShadowOffset:NSMakeSize(0, -1)]; 
	[theShadow setShadowBlurRadius:0.3]; 

	[theShadow setShadowColor:mShadowColor]; 
	
	[theShadow set];

	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];
	[theShadow release]; 
}

@end
