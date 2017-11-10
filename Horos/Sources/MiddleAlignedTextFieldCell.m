//
//  MiddleAlignedTextFieldCell.m
//  Horos
//
//  Created by Fauze Polpeta on 5/17/16.
//  Copyright © 2016 The Horos Project. All rights reserved.
//

#import "MiddleAlignedTextFieldCell.h"

@implementation MiddleAlignedTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y - .5 + (theRect.size.height - titleSize.height) / 2.0;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

@end
