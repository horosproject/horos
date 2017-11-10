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


#import "DragMatrixWithDelete.h"
#import "DCMView.h"
#import "Notifications.h"


@implementation DragMatrixWithDelete

static NSString  *pasteBoardTypeCover = @"KeyImages";

/*****************************************************************************
 * Function - initWithCoder
 *
 * Initialize and register ourself for drag operation.  Note since we use
 * a private user defined drag type (pasteBoardTypeCover) we will only
 * accept drags from within this app. This is called when we've been loaded
 * from an NIB.
*****************************************************************************/
- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
	{
        [self registerForDraggedTypes:[NSArray arrayWithObjects:pasteBoardTypeCover, pasteBoardOsiriX, nil]];
    }
    return self;
}
 
/*****************************************************************************
 * Function - initWithFrame
 *
 * Initialize and register ourself for drag operation.  Note since we use
 * a private user defined drag type (pasteBoardTypeCover) we will only
 * accept drags from within this app.  This is called when we've been created
 * dynamically (as opposed to loaded from a NIB).
*****************************************************************************/
- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame])
	{
        [self registerForDraggedTypes:[NSArray arrayWithObjects:pasteBoardTypeCover, pasteBoardOsiriX, nil]];
    }
    return self;
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
	unichar c = [[event characters] characterAtIndex:0];
	
    if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
	{
		[arrayController remove:self];
		return YES;
	}
	else
		return NO;
}

- (void)mouseUp:(NSEvent *)event{
	[super mouseUp:event];
//	[arrayController select:self];
}

/*****************************************************************************
 * Function - performDragOperation (implements NSDraggingDestination)
 *
 * Called after the user releases the drag object.  Here we perform the
 * result of the dragging.
*****************************************************************************/
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if ([sender draggingSource] == self)
		return NO;
	
    NSPasteboard *pboard;
    NSArray *types;
    pboard = [sender draggingPasteboard];
    types = [pboard types];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *dict;
    if ([types indexOfObject:pasteBoardTypeCover] != NSNotFound)
	{
		//[arrayController setSelectedObjects:[NSArray arrayWithObject:[[arrayController content] objectAtIndex:srcCol]]];
		NSArray *array = [[sender draggingSource] selection];
		//NSLog(@"Selection: 
        dict = [NSDictionary dictionaryWithObject:array forKey:@"images"];
        [nc postNotificationName:OsirixDragMatrixImageMovedNotification object:self userInfo:dict];
    }
	
	if ([types indexOfObject:pasteBoardOsiriX] != NSNotFound)
	{
		NSArray *array = nil;
		 id image = [(DCMView *)[sender draggingSource] dicomImage];
		 if (image)
			array = [NSArray arrayWithObject:image];
		//NSLog(@"Selection: 
		if (array)
		{
			dict = [NSDictionary dictionaryWithObject:array forKey:@"images"];
			[nc postNotificationName:OsirixDragMatrixImageMovedNotification object:self userInfo:dict];
		}
	}
    
    [self clearDragDestinationMembers];
    [self setNeedsDisplay:TRUE];
    
    return YES;
}

@end
