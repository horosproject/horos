//
//  LayoutWindowController.m
//  OsiriX
//
//  Created by Lance Pysher on 12/5/06.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "LayoutWindowController.h"
#import "browserController.h"
#import "ViewerController.h"


@implementation LayoutWindowController

- (id)init{
	if (self = [super initWithWindowNibName:@"Layout"]) {
		NSMutableArray *controllers = [NSMutableArray array];
		NSEnumerator *enumerator = [[NSApp windows] objectEnumerator];
		id	controller;
	
		while (controller = [enumerator nextObject])
		{
			//right now just 2D Viewers will need to deal with other viewer classed evnetually
			//?Arrange controller by screen and origin.  First by screen then by x (lees first) then by y (greater first)
			if([controller isKindOfClass:[ViewerController class]])
				[controllers addObject:controller];
		}
		_windowControllers = [controller copy];
	}
	return self;
}

- (void)dealloc{
	[_windowControllers release];
	[super dealloc];
}

- (void)windowDidLoad{
	NSLog(@"Layout window did load");
	
}

- (IBAction)endSheet:(id)sender{
	[[self window] orderOut:sender];
	[NSApp endSheet: [self window] returnCode:[sender tag]];
	 //returnCode:[sender tag]
}
	

@end
