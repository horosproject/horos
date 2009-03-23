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

#import "LoupeController.h"


@implementation LoupeController

- (id)init;
{
	if(![super initWithWindowNibName:@"Loupe"]) return nil;
	return self;
}

- (void)setTexture:(char*)texture withSize:(NSSize)textureSize bytesPerRow:(int)bytesPerRow rotation:(float)rotation;
{
	NSRect frame = [[self window] frame];
	
	[loupeView setTexture:texture withSize:textureSize bytesPerRow:bytesPerRow rotation:rotation];
//	[loupeView setNeedsDisplay:YES];
}

//- (void)setTexture:(char*)texture withSize:(NSSize)textureSize bytesPerRow:(int)bytesPerRow viewSize:(NSSize)viewSize;
//{
//	NSRect frame = [[self window] frame];
//
//	if(frame.size.width!=viewSize.width || frame.size.height!=viewSize.height)
//	{
//		NSPoint origin = frame.origin;
//		NSPoint center = NSMakePoint(origin.x+frame.size.width*0.5, origin.y+frame.size.height*0.5);
//		
//		NSPoint newOrigin;
//		newOrigin.x = center.x-frame.size.width*0.5;
//		newOrigin.y = center.y-frame.size.height*0.5;
//
//		NSRect newFrame = NSMakeRect(newOrigin.x, newOrigin.y, frame.size.width, frame.size.height);
//		[[self window] setFrame:newFrame display:YES];
//		//[loupeView setFrame:NSMakeRect(0, 0, viewSize.width, viewSize.height)];
//	}
//	
//	[loupeView setTexture:texture withSize:textureSize bytesPerRow:bytesPerRow];
//	[loupeView setNeedsDisplay:YES];
//}

- (void)centerWindowOnMouse;
{
	[self setWindowCenter:[NSEvent mouseLocation]];
}

- (void)setWindowCenter:(NSPoint)center;
{
	NSRect frame = [[self window] frame];
	NSPoint origin;
	
	origin.x = center.x-frame.size.width*0.5;
	origin.y = center.y-frame.size.height*0.5;
	
	//[[self window] setFrameOrigin:origin];
	[[self window] setFrame:NSMakeRect(origin.x, origin.y, frame.size.width, frame.size.height) display:NO];
	//[[[self window] contentView] setNeedsDisplay:YES];	
}

- (void)drawLoupeBorder:(BOOL)drawLoupeBorder;
{
	loupeView.drawLoupeBorder = drawLoupeBorder;
}

@end
