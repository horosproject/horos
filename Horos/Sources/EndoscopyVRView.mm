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

#import "EndoscopyVRView.h"
#import "EndoscopyViewer.h"

@implementation EndoscopyVRView

- (void) exportDICOMFile:(id) sender
{
	[NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

-(void) mouseMoved: (NSEvent*) theEvent
{
	if( ![[self window] isVisible])
		return;
	
	NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
	
	if( view == self)
		[super mouseMoved: theEvent];
	else
		[view mouseMoved:theEvent];
}
//path navigator
- (void) keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
    unichar c = [[event characters] characterAtIndex:0];
    
	if( c ==  NSUpArrowFunctionKey)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PathAssistantGoForwardNotification" object:nil userInfo:0L];
	}
	else if( c ==  NSDownArrowFunctionKey)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PathAssistantGoBackwardNotification" object:nil userInfo:0L];
	}
	else 
	{
		[super keyDown: event];
	}
}

//path navigator
- (void)scrollWheel:(NSEvent *)theEvent
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"PATH_ASSISTANT_USES_SCROLLWHEEL"])
	{
		if([theEvent deltaY]>0)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"PathAssistantGoForwardNotification" object:nil userInfo:0L];
		}
		else if([theEvent deltaY]<0)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"PathAssistantGoBackwardNotification" object:nil userInfo:0L];
		}
	}	
}


-(id)initWithFrame:(NSRect)frame;
{
    if ( self = [super initWithFrame:frame] )
    {
		[self connect2SpaceNavigator];
		
//		dontUseAutoCropping = YES;
		
		superSampling = 4.0;
	}
	return self;
}

-(unsigned char*) superGetRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	return [super getRawPixels:width :height :spp :bpp :screenCapture :force8bits];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	if ([(EndoscopyViewer*)[[self window] windowController] exportAllViews])
		return [(EndoscopyViewer*)[[self window] windowController] getRawPixels:width :height :spp :bpp];
	else
		return [super getRawPixels:width :height :spp :bpp :screenCapture :force8bits];
}

-(void) restoreViewSizeAfterMatrix3DExport
{
}

-(void) setViewSizeToMatrix3DExport
{
}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower
{
	[super setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower];
}

- (void) setSelectionIndex:(float) ambient :(float) diffuse :(float) specular :(float) specularpower
{
	[super setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower];
}

- (void)setIChatFrame:(BOOL)set;
{
	return;
}

@end
