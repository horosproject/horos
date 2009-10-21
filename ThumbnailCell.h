//
//  ThumbnailCell.h
//  OsiriX
//
//  Created by antoinerosset on 13.07.08.
//  Copyright 2008 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ThumbnailCell : NSButtonCell {
	BOOL rightClick;
}

@property(readonly) BOOL rightClick;

@end
