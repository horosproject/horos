//
//  SRArrayController.m
//  SR
//
//  Created by Lance Pysher on 5/25/06.
//  Copyright 2006 Macrad, LLC. All rights reserved.
//

#import "SRArrayController.h"


@implementation SRArrayController

- (IBAction)chooseAction:(id)sender{
	// allows to use anNSSegmentedControl
	if ([sender selectedSegment] == 0)
		[self add:sender];
	else
		[self remove:sender];
}





@end
