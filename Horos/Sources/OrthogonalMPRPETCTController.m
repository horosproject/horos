/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "OrthogonalMPRPETCTController.h"
#import "OrthogonalMPRPETCTView.h"
#import "OrthogonalMPRPETCTViewer.h"
#import "OrthogonalMPRViewer.h"
#import "Notifications.h"

@implementation OrthogonalMPRPETCTController

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC :(id) newViewer
{
	self = [super initWithPixList: pix : files : vData : vC : bC : newViewer];

	isBlending = (bC != nil);
	
	return self;
}

- (void) setCrossPosition: (float) x :(float) y :(id) sender
{
	if ([sender isEqual: originalView])
	{
		[viewer resliceFromOriginal:x:y:self];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[viewer resliceFromX:x:y:self];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[viewer resliceFromY:x:y:self];
	}
}

- (void) doubleClick:(NSEvent *)event :(id) sender
{
	if ([event modifierFlags] & NSAlternateKeyMask)
	{
		[self fullWindowView: sender];
	}
	else if ([event modifierFlags] & NSShiftKeyMask)
	{
		[self fullWindowModality: sender];
	}
	else
	{
		[self fullWindowPlan: sender];
	}
	
	// trick to refresh the view
	NSRect frame = [[viewer window] frame];
	[[viewer window] setFrame:NSMakeRect(frame.origin.x,frame.origin.y,frame.size.width+1,frame.size.height+1) display:NO];
	[[viewer window] setFrame:frame display:YES];
}

- (void) fullWindowPlan: (id) sender
{
	if ([sender isEqual: originalView])
	{
		[viewer fullWindowPlan:0:self];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[viewer fullWindowPlan:1:self];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[viewer fullWindowPlan:2:self];
	}
}

- (void) fullWindowModality: (id) sender
{
	if ([sender isEqual: originalView])
	{
		[(OrthogonalMPRPETCTViewer*)viewer fullWindowModality:0:self];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[viewer fullWindowModality:1:self];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[viewer fullWindowModality:2:self];
	}
}

- (void) fullWindowView: (id) sender
{
	if ([sender isEqual: originalView])
	{
		[viewer fullWindowView:0:self];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[viewer fullWindowView:1:self];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[viewer fullWindowView:2:self];
	}
}

- (void) scaleToFit
{
	[super scaleToFit];
}

- (void) resliceFromOriginal: (float) x :(float) y
{
	[originalView setCrossPositionX:x];
	[originalView setCrossPositionY:y];
	[self reslice:x:y:originalView];
}

- (void) resliceFromX: (float) x :(float) y
{
	[xReslicedView setCrossPositionX:x];
	[xReslicedView setCrossPositionY:y];
	[self reslice:x:y:xReslicedView];
}

- (void) resliceFromY: (float) x :(float) y
{
	[yReslicedView setCrossPositionX:x];
	[yReslicedView setCrossPositionY:y];
	[self reslice:x:y:yReslicedView];
}

- (void) stopBlending
{
	[originalView setBlending: nil];
	[xReslicedView setBlending: nil];
	[yReslicedView setBlending: nil];
}

- (void) reslice: (long) x :(long) y :(OrthogonalMPRView*) sender
{
	float originalScaleValue, xScaleValue, yScaleValue, originalRotation, xRotation, yRotation, blendingFactor;

	originalRotation = 0;
	xRotation = 0;
	yRotation = 0;
	
	NSPoint originalOrigin, xOrigin, yOrigin;
	
	BOOL originalOldValues, xOldValues, yOldValues, originalFlippedX, xFlippedX, yFlippedX, originalFlippedY, xFlippedY, yFlippedY;
	originalOldValues = xOldValues = yOldValues = originalFlippedX = xFlippedX = yFlippedX = originalFlippedY = xFlippedY = yFlippedY = NO;

	if ([originalView dcmPixList] != nil)
	{
		originalScaleValue = [originalView scaleValue];
		originalRotation = [originalView rotation];
		originalOrigin = [originalView origin];
		originalOldValues = YES;
		originalFlippedX = [originalView xFlipped];
		originalFlippedY = [originalView yFlipped];
		blendingFactor = [originalView blendingFactor];
	}

	if ([xReslicedView dcmPixList] != nil)
	{
		xScaleValue = [xReslicedView scaleValue];
		xRotation = [xReslicedView rotation];
		xOrigin = [xReslicedView origin];
		xOldValues = YES;
		xFlippedX = [xReslicedView xFlipped];
		xFlippedY = [xReslicedView yFlipped];
		blendingFactor = [xReslicedView blendingFactor];
	}
	
	if ([yReslicedView dcmPixList] != nil)
	{
		yScaleValue = [yReslicedView scaleValue];
		yRotation = [yReslicedView rotation];
		yOrigin = [yReslicedView origin];
		yOldValues = YES;
		yFlippedX = [yReslicedView xFlipped];
		yFlippedY = [yReslicedView yFlipped];
		blendingFactor = [yReslicedView blendingFactor];
	}
	
	if(!isBlending)
	{
		[super reslice: x: y: sender];
	}
	else
	{
		[originalView setPixels:[[[viewer CTController] originalView] pixList]  files:originalDCMFilesList rois:nil firstImage:[[[viewer CTController] originalView] curImage] level:1 reset:YES];
		[xReslicedView setPixels:[[[viewer CTController] xReslicedView] pixList]  files:originalDCMFilesList rois:nil firstImage:0 level:1 reset:YES];
		[yReslicedView setPixels:[[[viewer CTController] yReslicedView] pixList]  files:originalDCMFilesList rois:nil firstImage:0 level:1 reset:YES];
		
		[originalView setBlending:[[viewer PETController] originalView]];
		[originalView setBlendingFactor: blendingFactor];
		[originalView setIndex: [[[viewer CTController] originalView] curImage]];
		
		// cross position
		[originalView setCrossPositionX:[[[viewer CTController] originalView] crossPositionX]];
		[originalView setCrossPositionY:[[[viewer CTController] originalView] crossPositionY]];
		
		[xReslicedView setBlending:[[viewer PETController] xReslicedView]];
		[xReslicedView setBlendingFactor: blendingFactor];
		[xReslicedView setIndex:0];

		// cross position
		[xReslicedView setCrossPositionX:[[[viewer CTController] xReslicedView] crossPositionX]];
		[xReslicedView setCrossPositionY:[[[viewer CTController] xReslicedView] crossPositionY]];
				
		[yReslicedView setBlending:[[viewer PETController] yReslicedView]];
		[yReslicedView setBlendingFactor: blendingFactor];
		[yReslicedView setIndex:0];

		// cross position
		[yReslicedView setCrossPositionX:[[[viewer CTController] yReslicedView] crossPositionX]];
		[yReslicedView setCrossPositionY:[[[viewer CTController] yReslicedView] crossPositionY]];
	}

	if(xOldValues)
	{
		// scale
		[xReslicedView setScaleValue:xScaleValue];
		// rotation
		[xReslicedView setRotation:xRotation];
		// origin
		[xReslicedView setOrigin:xOrigin];
		// horizontally flipped
		[xReslicedView setXFlipped:xFlippedX];
		// vertically flipped
		[xReslicedView setYFlipped:xFlippedY];
	}

	if(yOldValues)
	{
		// scale
		[yReslicedView setScaleValue:yScaleValue];
		// rotation
		[yReslicedView setRotation:yRotation];
		// origin
		[yReslicedView setOrigin:yOrigin];
		// horizontally flipped
		[yReslicedView setXFlipped:yFlippedX];
		// vertically flipped
		[yReslicedView setYFlipped:yFlippedY];

	}
	
	if(originalOldValues) 
	{
		// scale
		[originalView setScaleValue:originalScaleValue];
		// rotation
		[originalView setRotation:originalRotation];
		// origin
		[originalView setOrigin:originalOrigin];
		// horizontally flipped
		[originalView setXFlipped:originalFlippedX];
		// vertically flipped
		[originalView setYFlipped:originalFlippedY];
	}

	[self blendingPropagate: originalView];
	[self blendingPropagate: xReslicedView];
	[self blendingPropagate: yReslicedView];

	[originalView setNeedsDisplay: YES];
	[xReslicedView setNeedsDisplay: YES];
	[yReslicedView setNeedsDisplay: YES];
}

- (void) flipVertical:(id) sender :(OrthogonalMPRPETCTView*) view
{
	if ([view isEqual: originalView])
	{	
		[viewer flipVerticalOriginal:sender];
	}
	else if ([view isEqual: xReslicedView])
	{
		[viewer flipVerticalX:sender];
	}
	else if ([view isEqual: yReslicedView])
	{
		[viewer flipVerticalY:sender];
	}
}

- (void) flipHorizontal:(id) sender :(OrthogonalMPRPETCTView*) view
{
	if ([view isEqual: originalView])
	{	
		[viewer flipHorizontalOriginal:sender];
	}
	else if ([view isEqual: xReslicedView])
	{
		[viewer flipHorizontalX:sender];
	}
	else if ([view isEqual: yReslicedView])
	{
		[viewer flipHorizontalY:sender];
	}
}

//- (void) changeWLWW: (NSNotification*) note
//{
//	DCMPix	*otherPix = [note object];
//	
//	if( [originalDCMPixList containsObject: otherPix])
//	{
//		float iwl, iww;
//		
//		iww = [otherPix ww];
//		iwl = [otherPix wl];
//		
//		if( iww != [[originalView curDCM] ww] || iwl != [[originalView curDCM] wl]) [self setWLWW: iwl :iww];
//	}
//}

- (void) setWLWW:(float) iwl :(float) iww
{
	[super setWLWW: iwl : iww];
	[viewer setWLWW: iwl : iww : self];
	[self setCurWLWWMenu: NSLocalizedString(@"Other", nil)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixChangeWLWWNotification object: [originalView curDCM] userInfo:nil];
}

- (void) superSetWLWW:(float) iwl :(float) iww
{
	[super setWLWW: iwl : iww];
}

-(void) setBlendingFactor:(float) f
{
	[(OrthogonalMPRPETCTView*) originalView superSetBlendingFactor:f];
	[(OrthogonalMPRPETCTView*) xReslicedView superSetBlendingFactor:f];
	[(OrthogonalMPRPETCTView*) yReslicedView superSetBlendingFactor:f];
	[viewer moveBlendingFactorSlider:f];
}

-(void) setBlendingMode:(long) f
{
	[originalView setBlendingMode:f];
	[xReslicedView setBlendingMode:f];
	[yReslicedView setBlendingMode:f];
}

- (void) resetImage
{
	[super resetImage];
	[originalView setBlendingFactor: 0];
	[xReslicedView setBlendingFactor: 0];
	[yReslicedView setBlendingFactor: 0];
}

- (BOOL) containsView: (DCMView*) view
{
	return ([view isEqualTo:originalView] || [view isEqualTo:xReslicedView] || [view isEqualTo:yReslicedView]);
}

-(void) ApplyCLUTString:(NSString*) str
{
	[super ApplyCLUTString:str];
	[(OrthogonalMPRPETCTView*)originalView setCurCLUTMenu: str];
	[(OrthogonalMPRPETCTView*)xReslicedView setCurCLUTMenu: str];
	[(OrthogonalMPRPETCTView*)yReslicedView setCurCLUTMenu: str];
}

-(void) ApplyOpacityString:(NSString*) str
{
	[super ApplyOpacityString:str];
	[(OrthogonalMPRPETCTView*)originalView setCurOpacityMenu: str];
	[(OrthogonalMPRPETCTView*)xReslicedView setCurOpacityMenu: str];
	[(OrthogonalMPRPETCTView*)yReslicedView setCurOpacityMenu: str];
}

@end
