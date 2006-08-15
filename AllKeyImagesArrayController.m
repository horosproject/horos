//
//  AllKeyImagesArrayController.m
//  OsiriX
//
//  Created by Lance Pysher on 8/11/06.

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


#import "AllKeyImagesArrayController.h"
#import "DicomImage.h"
#import "DragMatrix.h"

@implementation AllKeyImagesArrayController


- (void)setContent:(id)content{
	[super setContent:content];
	if (keyImageMatrix)
		[self updateMatrix];
	[(DragMatrix *)keyImageMatrix setController:self];
}


- (void)updateMatrix{
	int columns = [keyImageMatrix numberOfColumns];
	while (columns-- > 0)
		[keyImageMatrix removeColumn:columns];
	int count = [[self content] count];
	//while (count-- > 0)
	//	[keyImageMatrix addColumn];
	//NSLog(@"columns after : %d", columns);	
	NSEnumerator *enumerator = [[self content] objectEnumerator];
	DicomImage *image;
	while (image = [enumerator nextObject]) {
		NSImage *thumbnail = [image thumbnail];
		if (thumbnail) {
			//NSImageCell *cell = [[[NSImageCell alloc] initImageCell:thumbnail] autorelease];
			NSButtonCell *cell = [[[NSButtonCell alloc] initImageCell:thumbnail] autorelease];
			[keyImageMatrix addColumnWithCells:[NSArray arrayWithObject:cell]];
		}
	}
	//keyImageMatrix

}
	



@end
