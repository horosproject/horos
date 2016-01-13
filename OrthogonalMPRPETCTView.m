/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/

#import "OrthogonalMPRController.h"
#import "OrthogonalMPRPETCTView.h"
#import "OrthogonalMPRPETCTController.h"
#import "Notifications.h"


@implementation OrthogonalMPRPETCTView

- (void) drawTextualData:(NSRect) size annotationsLevel:(long) annotations fullText: (BOOL) fullText onlyOrientation: (BOOL) onlyOrientation
{
	if( isKeyView == NO)
		[super drawTextualData: size annotationsLevel: annotations fullText: NO onlyOrientation: YES];
	else
		[super drawTextualData: size annotationsLevel: annotations fullText: NO onlyOrientation: NO];
}

- (void) dealloc
{
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	blendingFactor = 0.5f;
	return self;
}

-(void) setBlendingFactor:(float) f
{
	[controller setBlendingFactor:f];
}

-(void) superSetBlendingFactor:(float) f
{
	[super setBlendingFactor:f];
}

- (void) flipVertical:(id) sender
{
	[(OrthogonalMPRPETCTController*)controller flipVertical: sender : self];
}

- (void) superFlipVertical:(id) sender
{
	[super flipVertical: sender];
}

- (void) flipHorizontal:(id) sender
{
	[(OrthogonalMPRPETCTController*)controller flipHorizontal: sender : self];
}

- (void) superFlipHorizontal:(id) sender
{
	[super flipHorizontal: sender];
}

- (BOOL) becomeFirstResponder
{
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
	
	return [super becomeFirstResponder];
}

- (void) exportDICOMFile:(id) sender
{
    [self.windowController exportDICOMFile: sender];
}

-(void) sendMail:(id) sender
{
    [self.windowController sendMail: sender];
}

- (void) exportJPEG:(id) sender
{
    [self.windowController exportJPEG: sender];
}

- (void) MoviePlayStop:(id) sender
{
    [self.windowController MoviePlayStop: sender];
}

- (void) ApplyWLWW:(id) sender
{
    [self.windowController ApplyWLWW: sender];
}

- (void) ApplyCLUT:(id) sender
{
    [self.windowController ApplyCLUT: sender];
}

- (void) ApplyOpacity: (id) sender
{
    [self.windowController ApplyOpacity: sender];
}

- (void) flipVerticalOriginal: (id) sender
{
    [self.windowController flipVerticalOriginal: sender];
}

- (void) flipVerticalX: (id) sender
{
    [self.windowController flipVerticalX: sender];
}

- (void) flipVerticalY: (id) sender
{
    [self.windowController flipVerticalY: sender];
}

- (void) flipHorizontalOriginal: (id) sender
{
    [self.windowController flipHorizontalOriginal: sender];
}

- (void) flipHorizontalX: (id) sender
{
    [self.windowController flipHorizontalX: sender];
}

- (void) flipHorizontalY: (id) sender
{
    [self.windowController flipHorizontalY: sender];
}

- (IBAction) changeTool:(id) sender
{
    [self.windowController changeTool: sender];
}

- (IBAction) changeBlendingFactor:(id) sender
{
    [self.windowController changeBlendingFactor: sender];
}

- (IBAction) blendingMode:(id) sender
{
    [self.windowController blendingMode: sender];
}

- (IBAction) resetImage:(id) sender
{
    [self.windowController resetImage: sender];
}


@end
