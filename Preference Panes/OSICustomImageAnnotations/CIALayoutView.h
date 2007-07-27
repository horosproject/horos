//
//  CIALayoutView.h
//  ImageAnnotations
//
//  Created by joris on 25/06/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CIALayoutView : NSView {
	NSArray *placeHolderArray;
}

- (void)updatePlaceHolderOrigins;
- (void)updatePlaceHolderOriginsInRect:(NSRect)rect;
- (NSArray*)placeHolderArray;

@end
