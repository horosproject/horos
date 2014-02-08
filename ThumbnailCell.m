#import "ThumbnailCell.h"
#import "O2ViewerThumbnailsMatrix.h"

#define FULLSIZEHEIGHT 120
#define HALFSIZEHEIGHT 60
#define SIZEWIDTH 100

@implementation ThumbnailCell

@synthesize rightClick;

+ (float) thumbnailCellWidth
{
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
    {
        case -1:   return SIZEWIDTH * 0.8; break;
        case 0:    return SIZEWIDTH; break;
        case 1:    return SIZEWIDTH * 1.3; break;

    }
    return SIZEWIDTH;
}

- (NSMenu *)menuForEvent:(NSEvent *)anEvent inRect:(NSRect)cellFrame ofView:(NSView *)aView
{
    [self retain];
    
	rightClick = YES;
	[self performClick: self];
	rightClick = NO;
	
    [self autorelease];
    
	return nil;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    [super drawBezelWithFrame:frame inView:controlView];
    if (self.backgroundColor) {
        
        if( !invertedSet)
            invertedColors = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue];
        
        NSColor *backc = [[self.backgroundColor copy] autorelease];
        
        if( invertedColors)
            backc = [NSColor colorWithCalibratedRed: 1.0-backc.redComponent green: 1.0-backc.greenComponent blue: 1.0-backc.blueComponent alpha: backc.alphaComponent];
        
        [NSGraphicsContext saveGraphicsState];
        [[backc colorWithAlphaComponent:0.75] setFill];
        [NSBezierPath fillRect:NSInsetRect(frame, 1, 1)];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
    return [super drawTitle:title withFrame:NSInsetRect(frame, -2,0) inView:controlView]; // very precioussss 4px/pt
}

- (NSSize)cellSize
{
    O2ViewerThumbnailsMatrixRepresentedObject* oro = [self representedObject];
    
    float h = 0;
    
    if ([oro.object isKindOfClass:[NSManagedObject class]] || oro.children.count || oro == nil)
        h = FULLSIZEHEIGHT;
    else
        h = HALFSIZEHEIGHT;
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
    {
        case -1:    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h * 0.8); break;
        case 0:    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h); break;
        case 1:    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h * 1.3); break;
    }

    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h);
}

@end
