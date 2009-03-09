/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




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

+(id)zoomCursor{
	if (!zoomCursor)
		zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"ZoomCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return zoomCursor;
}
+(id)rotateCursor{
		if (!rotateCursor)
		rotateCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"RotateCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return rotateCursor;
}
+(id)crossCursor{
	if (!crossROICursor)
		crossROICursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crossCursor.tif"] hotSpot:NSMakePoint(10,10)];
	
	if( crossROICursor == nil) crossROICursor = [[NSCursor crosshairCursor] retain];
	
	return crossROICursor;
}
+(id)rotate3DCursor{
		if (!rotate3DCursor)
		rotate3DCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Rotate3DCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return rotate3DCursor;
}
+(id)rotate3DCameraCursor{
		if (!rotate3DCameraCursor)
		rotate3DCameraCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Rotate3DCameraCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return rotate3DCameraCursor;
}
+(id)stackCursor{
	if (!stackCursor)
	stackCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"StackCursor.tif"] hotSpot:NSMakePoint(7,7)];
	
	return stackCursor;

}

+(id)contrastCursor{
	if (!contrastCursor)
	contrastCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"ContrastCursor.tif"] hotSpot:NSMakePoint(4,1)];
	
	return contrastCursor;

}

+ (id) bonesRemovalCursor
{
	if (!bonesRemovalCursor)
		bonesRemovalCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"BonesRemovalCursor.tif"] hotSpot:NSMakePoint(7,7)];
	return bonesRemovalCursor;
}

+ (id) rotateAxisCursor
{
	if (!rotateAxisCursor)
		rotateAxisCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"RotateAxisCursor.png"] hotSpot:NSMakePoint(7,7)];
	return rotateAxisCursor;
}

@end
