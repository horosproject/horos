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

#import "NSImage+OsiriX.h"
#import "N2Debug.h"

#include "options.h"

extern unsigned char* compressJPEG(int inQuality, unsigned char* inImageBuffP, int inImageHeight, int inImageWidth, int monochrome, int *destSize);
extern NSRecursiveLock* PapyrusLock;

@implementation NSImage (OsiriX)

-(NSData*)JPEGRepresentationWithQuality:(CGFloat)quality
{
	NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:self.TIFFRepresentation];
	NSData* result = NULL;
	NSDictionary* imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:quality]
                                                               forKey:NSImageCompressionFactor];
	result = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
	
	return result;	
}

@end

