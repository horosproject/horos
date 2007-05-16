//
//  ColorView.h
//  OsiriX
//
//  Created by joris on 15/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ColorView : NSView {
	NSColor *color;
}

- (void)setColor:(NSColor*)newColor;

@end
