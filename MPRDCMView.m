//
//  MPRDCMView.m
//  OsiriX
//
//  Created by joris on 2/26/09.
//  Copyright 2009 The OsiriX Foundation. All rights reserved.
//

#import "MPRDCMView.h"


@implementation MPRDCMView

- (void)setDCMPixList:(NSMutableArray*)pix filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
{
	[super setDCM:pix :files :rois :firstImage :type :reset];
}

- (void) dealloc
{
	[super dealloc];
}


@end
 