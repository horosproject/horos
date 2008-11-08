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

#import "LLDCMView.h"
#import "ROI.h"

@implementation LLDCMView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	[self setStringID:@"OrthogonalMPRVIEW"];
	return self;
}

- (void) blendingPropagate
{
	[viewer blendingPropagate:self];
}

- (void) setIndexWithReset:(short) index :(BOOL) sizeToFit
{
	if( dcmPixList && index != -1)
    {
		[[self window] setAcceptsMouseMovedEvents: YES];

		curROI = nil;
		
		origin.x = origin.y = 0;
		curImage = index; 
		if( curImage >= [dcmPixList count]) curImage = [dcmPixList count] -1;
		curDCM = [dcmPixList objectAtIndex: curImage];
		
		[curRoiList release];
		
		if( dcmRoiList) curRoiList = [[dcmRoiList objectAtIndex: curImage] retain];
		else
		{
			curRoiList = [[NSMutableArray alloc] initWithCapacity:0];
		}
		
		for( id loopItem in curRoiList)
		{
			[loopItem setRoiFont: labelFontListGL :labelFontListGLSize :self];
			[loopItem recompute];
			// Unselect previous ROIs
			[loopItem setROIMode : ROI_sleep];
		}
		
		curWW = [curDCM ww];
		curWL = [curDCM wl];
		
		rotation = 0;
		
		//get Presentation State info from series Object
		[self updatePresentationStateFromSeries];
		
		[curDCM checkImageAvailble :curWW :curWL];
		
//		NSSize  sizeView = [[self enclosingScrollView] contentSize];
//		[self setFrameSize:sizeView];
		
		if( sizeToFit || [[[self window] windowController] is2DViewer] == NO) {
			[self scaleToFit];
		}
		
		if( [[[self window] windowController] is2DViewer] == YES)
		{
			if( [curDCM sourceFile])
			{
				if( [[[self window] windowController] is2DViewer] == YES) [[self window] setRepresentedFilename: [curDCM sourceFile]];
			}
		}
		
		[self loadTextures];
		[self setNeedsDisplay:YES];
		
//		if( [[[self window] windowController] is2DViewer] == YES)
//			[[[self window] windowController] propagateSettings];
		
//		if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
//		if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];

		[yearOld release];
		yearOld = [[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"] retain];
	}
}

@end
