//
//  LLScoutOrthogonalReslice.m
//  OsiriX
//
//  Created by Joris Heuberger on 19/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

#import "LLScoutOrthogonalReslice.h"


@implementation LLScoutOrthogonalReslice

- (void) reslice : (long) x : (long) y
{
	[self xReslice:y];
}

- (void) yReslice: (long) y{}

- (NSMutableArray*) yReslicedDCMPixList
{
	return originalDCMPixList;
}

@end
