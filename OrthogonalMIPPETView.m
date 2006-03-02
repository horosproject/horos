//
//  OrthogonalMIPPETView.m
//  OsiriX
//
//  Created by joris on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OrthogonalMIPPETView.h"


@implementation OrthogonalMIPPETView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	[self setStringID:@"OrthogonalMIP"];
	return self;
}

- (void) setPixList: (NSMutableArray*) pix //:(NSArray*) files
{
	NSLog( @"view setPixList");
	[self setDCM:pix :nil :nil :0 :1 :YES];
	[self setIndex:0];
	float wl, ww;
	[self getWLWW:&wl :&ww];
	[self setWLWW:wl :ww];
//	[self loadTextures];
//	[self setNeedsDisplay:YES];
}

//- (void) setPixList: (NSMutableArray*) pix
//{
//	[self setDCM:pix :dcmFilesList :nil :0 :1 :YES];
//}

@end
