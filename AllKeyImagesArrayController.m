/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

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
}

- (void)updateMatrix
{
	int columns = [keyImageMatrix numberOfColumns];
	while (columns-- > 0)
		[keyImageMatrix removeColumn:columns];
		
	NSEnumerator *enumerator = [[self content] objectEnumerator];
	DicomImage *image;
	int tag = 0;
	while (image = [enumerator nextObject])
	{
		NSImage *thumbnail = [image thumbnail];
		if (thumbnail) {
			NSButtonCell *cell = [[[NSButtonCell alloc] initImageCell:thumbnail] autorelease];
			[cell setTag:tag++];
			[keyImageMatrix addColumnWithCells:[NSArray arrayWithObject:cell]];
		}
	}
	
	[keyImageMatrix sizeToCells];
}

@end
