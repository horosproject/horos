//
//  ThumbnailCell.m
//  OsiriX
//
//  Created by antoinerosset on 13.07.08.
//  Copyright 2008 LaTour / HUG. All rights reserved.
//

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
