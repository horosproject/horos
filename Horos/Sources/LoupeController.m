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
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
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
