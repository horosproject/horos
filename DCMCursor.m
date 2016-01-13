/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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


#import "DCMCursor.h"

static NSCursor *zoomCursor;
static NSCursor *rotateCursor;
static NSCursor *rotate3DCursor;
static NSCursor *rotate3DCameraCursor;
static NSCursor *stackCursor;
static NSCursor *contrastCursor;
static NSCursor *bonesRemovalCursor;
static NSCursor *crossROICursor;
static NSCursor *rotateAxisCursor;

@implementation NSCursor (DCMCursor)

+(NSCursor*) zoomCursor
{
	if (!zoomCursor)
		zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"ZoomCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return zoomCursor;
}
+(NSCursor*) rotateCursor
{
		if (!rotateCursor)
		rotateCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"RotateCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return rotateCursor;
}
+(NSCursor*) crossCursor
{
	if (!crossROICursor)
		crossROICursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crossCursor.tif"] hotSpot:NSMakePoint(10,10)];
	
	if( crossROICursor == nil) crossROICursor = [[NSCursor crosshairCursor] retain];
	
	return crossROICursor;
}
+(NSCursor*) rotate3DCursor
{
		if (!rotate3DCursor)
		rotate3DCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Rotate3DCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return rotate3DCursor;
}
+(NSCursor*) rotate3DCameraCursor
{
		if (!rotate3DCameraCursor)
		rotate3DCameraCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Rotate3DCameraCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return rotate3DCameraCursor;
}
+(NSCursor*) stackCursor
{
	if (!stackCursor)
	stackCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"StackCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return stackCursor;

}
+(NSCursor*) contrastCursor
{
	if (!contrastCursor)
	contrastCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"ContrastCursor.tif"] hotSpot:NSMakePoint(4,1)];
	
	return contrastCursor;

}
+(NSCursor*) bonesRemovalCursor
{
	if (!bonesRemovalCursor)
		bonesRemovalCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"BonesRemovalCursor.tif"] hotSpot:NSMakePoint(7,7)];
	return bonesRemovalCursor;
}
+(NSCursor*) rotateAxisCursor
{
	if (!rotateAxisCursor)
		rotateAxisCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"RotateAxisCursor.png"] hotSpot:NSMakePoint(7,7)];
	return rotateAxisCursor;
}

@end
