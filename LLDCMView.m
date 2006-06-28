//
//  LLDCMView.m
//  OsiriX
//
//  Created by joris on 28/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "LLDCMView.h"


@implementation LLDCMView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	[self setStringID:@"OrthogonalMPRVIEW"];
	return self;
}

- (void) blendingPropagate
{
	NSLog(@"LLDCMView blendingPropagate");
	[viewer blendingPropagate:self];
}

//- (void) setScaleValue:(float) x
//{
//	[viewer setScaleValue :x];
//}
//
//- (void) adjustScaleValue:(float) x
//{
//	[super setScaleValueCentered:x];
//}


@end
