//
//  SelectedKeyImagesArrayController.m
//  OsiriX
//
//  Created by Lance Pysher on 8/14/06.

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


#import "SelectedKeyImagesArrayController.h"


@implementation SelectedKeyImagesArrayController

- (void)awakeFromNib{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addKeyImages:) name:@"DragMatrixImageMoved" object:nil];
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}




- (void)addKeyImages:(NSNotification *)note{
	NSArray *keyImages = [[note userInfo] objectForKey:@"images"];
	NSEnumerator *enumerator = [keyImages objectEnumerator];
	id image;
	while (image = [enumerator nextObject]){
		if (![[self content] containsObject:image]) {
			[self addObject:image];
			[keyImageMatrix addColumn];
		}
	}
	
}


@end
