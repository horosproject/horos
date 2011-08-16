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

#import "AlbumCell.h"
#import "NSString+N2.h"

@implementation AlbumCell

@synthesize rightText = _rightText;

-(void)dealloc {
   // self.rightText = nil;
    [super dealloc];
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    NSRect initialFrame = frame;
    static const CGFloat spacer = 2;
    
    if (self.rightText) {
        NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
        NSMutableParagraphStyle* rightAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [rightAlignmentParagraphStyle setAlignment:NSRightTextAlignment];
        [attributes setObject:rightAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];

        frame.origin.y += 2;
        [self.rightText drawInRect:frame withAttributes:attributes];
        frame.origin.y -= 2;
        
        CGFloat w = [self.rightText sizeWithAttributes:attributes].width;
        frame.size.width -= w + spacer;
    }
    
    frame.origin.x += spacer;
    frame.size.width -= spacer;
	[super drawTitle:title withFrame:frame inView:controlView];
    
    return initialFrame;
}

- (BOOL)trackMouse:(NSEvent*)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
    return NO;
}

@end
