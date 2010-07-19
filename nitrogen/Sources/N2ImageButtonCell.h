//
//  N2ImageButtonCell.h
//  OsiriX
//
//  Created by Alessandro Volz on 7/19/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface N2ImageButtonCell : NSButtonCell {
	NSImage* altImage;
}

@property(retain) NSImage* altImage;

-(id)initWithImage:(NSImage*)image altImage:(NSImage*)altImage;

@end
