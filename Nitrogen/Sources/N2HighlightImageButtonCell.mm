/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
