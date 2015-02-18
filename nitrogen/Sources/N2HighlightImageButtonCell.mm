/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "N2HighlightImageButtonCell.h"


@implementation N2HighlightImageButtonCell

+(NSImage*)highlightedImage:(NSImage*)image {
	if (!image)
		return NULL;
	
	NSImage* highlightedImage = NULL;
	
	NSUInteger w = image.size.width, h = image.size.height;
	highlightedImage = [[NSImage alloc] initWithSize:image.size];
	[highlightedImage lockFocus];
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	
	for (NSUInteger y = 0; y < h; ++y)
		for (NSUInteger x = 0; x < w; ++x) {
			NSColor* c = [bitmap colorAtX:x y:y];
			c = [c highlightWithLevel:[c alphaComponent]/1.5];
			[bitmap setColor:c atX:x y:y];
		}
	
	[bitmap draw];
	[bitmap release];
	[highlightedImage unlockFocus];
	
	return [highlightedImage autorelease];	
}

-(id)initWithImage:(NSImage*)image {
	return [super initWithImage:image altImage:NULL]; // [N2HighlightImageButtonCell highlightedImage:image]
}

-(void)setImage:(NSImage*)image {
	[super setImage:image];
	self.altImage = [N2HighlightImageButtonCell highlightedImage:image];
}

@end
