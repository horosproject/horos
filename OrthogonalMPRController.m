/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "OrthogonalMPRController.h"
#import "OrthogonalMPRViewer.h"
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

#import "ROI.h"

@implementation OrthogonalMPRController

- (void) setCrossPosition: (float) x: (float) y: (id) sender
{
}

-(void) setBlendingFactor:(float) f
{
}

- (void) applyOrientation
{
	switch( orientationVector)
	{
		case 1:
			[xReslicedView setXFlipped: YES];
			if( [xReslicedView rotation] == 0) [xReslicedView setRotation: 90];
			
			[yReslicedView setXFlipped: YES];
			if( [yReslicedView rotation] == 0) [yReslicedView setRotation: 90];
		break;
		
		case 2:
			[xReslicedView setYFlipped: YES];
			if( [yReslicedView rotation] == 0) [yReslicedView setRotation: 90];
		break;
		
		case 4:
			// Classic Axial
		break;
		
		default:
			NSLog( @"Orientation Unknown: %d", orientationVector);
		break;
	}
}

- (id) initWithPixList: (NSArray*)pix :(NSArray*)files :(NSData*)vData :(ViewerController*)vC :(ViewerController*)bC :(id)newViewer
{
	if (self = [super init])
	{		
		// initialisations
		originalDCMPixList = [pix retain];
		originalDCMFilesList = [[NSMutableArray alloc] initWithArray:files];
		
		if( [vC blendingController] == 0L)
		{
			NSLog( @"originalROIList");
			originalROIList = [[[vC imageView] dcmRoiList] retain];
		}
		else
		{
			originalROIList = 0L;
		}
		
		reslicer = [[OrthogonalReslice alloc] initWithOriginalDCMPixList: originalDCMPixList];
			
		// Set the views (OrthogonalMPRView)
		[originalView setController:self];
		[xReslicedView setController:self];
		[yReslicedView setController:self];
			
		[originalView setCurrentTool:tCross];	
		[xReslicedView setCurrentTool:tCross];
		[yReslicedView setCurrentTool:tCross];
		
		viewer = newViewer;
		[originalView  setMenu:[self contextualMenu]];
		[xReslicedView setMenu:[self contextualMenu]];
		[yReslicedView setMenu:[self contextualMenu]];
		
		[[NSNotificationCenter defaultCenter]	addObserver: self
												selector: @selector(changeWLWW:)
												name: @"changeWLWW"
												object: nil];
		
		orientationVector = [vC orientationVector];
		[self applyOrientation];
	}
	
	return self;
}

- (void) dealloc
{
	NSLog(@"OrthogonalMPRController dealloc");
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[originalDCMPixList release];
	[originalDCMFilesList release];
	
	[originalROIList release];
	
	[reslicer release];
	
	[super dealloc];
}

/* nothing to do
- (void)finalize {
}
*/

#pragma mark-
#pragma mark Orthogonal reslice methods


- (void) reslice: (long) x: (long) y: (OrthogonalMPRView*) sender
{
	float originalScaleValue, xScaleValue, yScaleValue, originalRotation, xRotation, yRotation;

	originalRotation = 0;
	xRotation = 0;
	yRotation = 0;
	
	NSPoint originalOrigin, xOrigin, yOrigin;
	
	BOOL	originalOldValues, xOldValues, yOldValues;
	originalOldValues = xOldValues = yOldValues = NO;

	if ([originalView dcmPixList] != nil)
	{
		originalScaleValue = [originalView scaleValue];
		originalRotation = [originalView rotation];
		originalOrigin = [originalView origin];
		originalOldValues = YES;
	}

	if ([xReslicedView dcmPixList] != nil)
	{
		xScaleValue = [xReslicedView scaleValue];
		xRotation = [xReslicedView rotation];
		xOrigin = [xReslicedView origin];
		xOldValues = YES;
	}
	
	if ([yReslicedView dcmPixList] != nil)
	{
		yScaleValue = [yReslicedView scaleValue];
		yRotation = [yReslicedView rotation];
		yOrigin = [yReslicedView origin];
		yOldValues = YES;
	}
		
	if ([sender isEqual: originalView])
	{
		// orthogonal reslice on both axes
		[reslicer reslice:x:y];
		
		xReslicedDCMPixList = [reslicer xReslicedDCMPixList];
		yReslicedDCMPixList = [reslicer yReslicedDCMPixList];
		
		[xReslicedView setPixList : xReslicedDCMPixList :originalDCMFilesList];
		[yReslicedView setPixList : yReslicedDCMPixList :originalDCMFilesList];
		
//		// WLWW
		float wl, ww;
		[originalView getWLWW:&wl :&ww];
		[xReslicedView adjustWLWW:wl :ww];
		[yReslicedView adjustWLWW:wl :ww];
		
		// move cross on the other views
		[xReslicedView setCrossPositionX:x];
		[yReslicedView setCrossPositionX:y];
		long sliceIndex = [[originalView pixList] indexOfObject:[originalView curDCM]] + [[originalView curDCM] stack]/2;
		long h = (sign>0)? [[originalView dcmPixList] count]-sliceIndex-1 : sliceIndex ;

		[xReslicedView setCrossPositionY:h];
		[yReslicedView setCrossPositionY:h];
	}
	else
	{
		// slice index on axial view
		long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -y : y;
		
		sliceIndex = sliceIndex - thickSlab/2;
		
		if( sliceIndex < 0) sliceIndex = 0;
		if( sliceIndex >= [[originalView dcmPixList] count]) sliceIndex = [[originalView dcmPixList] count]-1;
		// update axial view
		[originalView setIndex:sliceIndex];
		
		if ([sender isEqual: xReslicedView])
		{
			[originalView setCrossPositionX:x];
			// compute 3rd view	
			[reslicer yReslice:x];
			yReslicedDCMPixList = [reslicer yReslicedDCMPixList];
			
			[yReslicedView setCurRoiList:[self pointsROIAtX:x]];
		
			[yReslicedView setPixList : yReslicedDCMPixList :originalDCMFilesList];
			
			// WLWW
			float wl, ww;
			[xReslicedView getWLWW:&wl :&ww];
			[originalView adjustWLWW:wl :ww];
			[yReslicedView adjustWLWW:wl :ww];

			// move cross on 3rd view
			[yReslicedView setCrossPositionY:y];
		}
		else if ([sender isEqual: yReslicedView])
		{
			[originalView setCrossPositionY:x];
			// compute 3rd view
			[reslicer xReslice:x];
			xReslicedDCMPixList = [reslicer xReslicedDCMPixList];
			
			[xReslicedView setCurRoiList:[self pointsROIAtY:y]];
			
			[xReslicedView setPixList : xReslicedDCMPixList :originalDCMFilesList];
			
			// WLWW
			float wl, ww;
			[yReslicedView getWLWW:&wl :&ww];
			[originalView adjustWLWW:wl :ww];
			[xReslicedView adjustWLWW:wl :ww];

			// move cross on 3rd view
			[xReslicedView setCrossPositionY:y];
		}
	}

	if(originalOldValues) 
	{
		// scale
		[originalView setScaleValue:originalScaleValue];
//		NSLog(@"originalScaleValue : %f", originalScaleValue);
		// rotation
		[originalView setRotation:originalRotation];
		// origin
		[originalView setOrigin:originalOrigin];
	}
		
	if(xOldValues)
	{
		// scale
		[xReslicedView setScaleValue:xScaleValue];
		// rotation
		[xReslicedView setRotation:xRotation];
		// origin
		[xReslicedView setOrigin:xOrigin];
	}
	
	if(yOldValues)
	{
		// scale
		[yReslicedView setScaleValue:yScaleValue];
		// rotation
		[yReslicedView setRotation:yRotation];
		// origin
		[yReslicedView setOrigin:yOrigin];
	}

	[self loadROIonReslicedViews: [originalView crossPositionX]: [originalView crossPositionY]];
	
	[self applyOrientation];
	
	// needs display
	[originalView setNeedsDisplay:YES];
	[xReslicedView setNeedsDisplay:YES];
	[yReslicedView setNeedsDisplay:YES];
}

-(void) flipVolume
{
	NSLog(@"flipVolume");
	
	sign = -sign;
	[reslicer flipVolume];
	[self reslice:	[originalView crossPositionX] : [originalView crossPositionY] :originalView];
	[xReslicedView setNeedsDisplay:YES];
	[yReslicedView setNeedsDisplay:YES];
}

#pragma mark-
#pragma mark DCMView methods

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender
{
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[originalView setScaleValue: fValue * [originalView pixelSpacing]];
	[originalView setRotation: [sender rotation]];
	
	NSPoint pan = [sender origin];
	NSPoint delta = [DCMPix originDeltaBetween:[originalView curDCM] And:[sender curDCM]];
	delta.x *= [sender scaleValue];
	delta.y *= [sender scaleValue];
	[originalView setOrigin: NSMakePoint( pan.x + delta.x, pan.y - delta.y)];
	
	NSPoint		pt;
	
	// X - Views
	pt.y = [xReslicedView origin].y;
	pt.x = [sender origin].x + delta.x;
	[xReslicedView setOrigin: pt];

	// Y - Views
	pt.y = [yReslicedView origin].y;
	pt.x = -[sender origin].y + delta.y;
	[yReslicedView setOrigin: pt];
}

- (void) blendingPropagateX:(OrthogonalMPRView*) sender
{
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[xReslicedView setScaleValue: fValue * [xReslicedView pixelSpacing]];
	[xReslicedView setRotation: [sender rotation]];

	NSPoint pan = [sender origin];
	NSPoint delta = [DCMPix originDeltaBetween:[xReslicedView curDCM] And:[sender curDCM]];
	delta.x *= [sender scaleValue];
	delta.y *= [sender scaleValue];
	delta.y = 0;
	[xReslicedView setOrigin: NSMakePoint( pan.x + delta.x, pan.y - delta.y)];
	
	NSPoint		pt;
	
	// X - Views
	pt.y = [originalView origin].y;
	pt.x = [sender origin].x + delta.x;
	[originalView setOrigin: pt];

	// Y - Views
	pt.x = [yReslicedView origin].x;
	pt.y = [sender origin].y + delta.y;
	[yReslicedView setOrigin: pt];
}

- (void) blendingPropagateY:(OrthogonalMPRView*) sender
{
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[yReslicedView setScaleValue: fValue * [yReslicedView pixelSpacing]];
	[yReslicedView setRotation: [sender rotation]];

	NSPoint pan = [sender origin];
	NSPoint delta = [DCMPix originDeltaBetween:[yReslicedView curDCM] And:[sender curDCM]];
	delta.x *= [sender scaleValue];
	delta.y *= [sender scaleValue];
	delta.y = 0;
	[yReslicedView setOrigin: NSMakePoint( pan.x + delta.x, pan.y - delta.y)];
	
	NSPoint		pt;
	
	// X - Views
	pt.x = [originalView origin].x;
	pt.y = -([sender origin].x + delta.x);
	[originalView setOrigin: pt];

	// Y - Views
	pt.x = [xReslicedView origin].x;
	pt.y = [sender origin].y + delta.y;
	[xReslicedView setOrigin: pt];
}

- (void) blendingPropagate:(OrthogonalMPRView*) sender
{
	if ([sender isEqual: originalView])
	{	
		[viewer blendingPropagateOriginal:sender];
		[originalView setNeedsDisplay:YES];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[viewer blendingPropagateX:sender];
		[xReslicedView setNeedsDisplay:YES];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[viewer blendingPropagateY:sender];
		[yReslicedView setNeedsDisplay:YES];
	}
}

-(void) ApplyCLUTString:(NSString*) str
{
	if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
	{
		[originalView setCLUT: 0L :0L :0L];
		[xReslicedView setCLUT: 0L :0L :0L];
		[yReslicedView setCLUT: 0L :0L :0L];
	}
	else
	{
		NSDictionary		*aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str];
		if (aCLUT)
		{
			array = [aCLUT objectForKey:@"Red"];
			for( i = 0; i < 256; i++)
			{
				red[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Green"];
			for( i = 0; i < 256; i++)
			{
				green[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Blue"];
			for( i = 0; i < 256; i++)
			{
				blue[i] = [[array objectAtIndex: i] longValue];
			}
			
			[originalView setCLUT:red :green: blue];
			[xReslicedView setCLUT:red :green: blue];
			[yReslicedView setCLUT:red :green: blue];

			[originalView setNeedsDisplay:YES];
			[xReslicedView setNeedsDisplay:YES];
			[yReslicedView setNeedsDisplay:YES];
		}
	}
}

- (void) changeWLWW: (NSNotification*) note
{
	DCMPix	*otherPix = [note object];
	
	if( [originalDCMPixList containsObject: otherPix])
	{
		float iwl, iww;
		
		iww = [otherPix ww];
		iwl = [otherPix wl];
		
		if( iww != [[originalView curDCM] ww] || iwl != [[originalView curDCM] wl])
		{
			[self setWLWW: iwl :iww];
		}
	}
}

- (void) setWLWW:(float) iwl :(float) iww
{
	[originalView adjustWLWW: iwl : iww];
	[xReslicedView adjustWLWW: iwl : iww];
	[yReslicedView adjustWLWW: iwl : iww];
	[self setCurWLWWMenu: NSLocalizedString(@"Other", 0L)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"changeWLWW" object: [originalView curDCM] userInfo:0L];
}

- (void) setCurWLWWMenu:(NSString*) str
{
	[originalView setCurWLWWMenu: str];
	[xReslicedView setCurWLWWMenu: str];
	[yReslicedView setCurWLWWMenu: str];
}

-(void) setScaleValue:(float) x
{
	[originalView adjustScaleValue: x];

	if( [xReslicedView pixelSpacingX] != 0 && [originalView pixelSpacingX] != 0)
	{
		float scaleValue = [originalView scaleValue];
		
		[xReslicedView adjustScaleValue: scaleValue * [xReslicedView pixelSpacingX] / [originalView pixelSpacingX]];
		[yReslicedView adjustScaleValue: scaleValue * [yReslicedView pixelSpacingX] / [originalView pixelSpacingX]];
	}
	else
	{
		[xReslicedView adjustScaleValue: x];	 
		[yReslicedView adjustScaleValue: x];
	}
}

- (void) resetImage
{
	[originalView setOrigin: NSMakePoint( 0, 0)];
	[originalView scaleToFit];
	[originalView setWLWW:[[originalView curDCM] savedWL] :[[originalView curDCM] savedWW]];
	[originalView setRotation: 0];
	[originalView setXFlipped:NO];
	[originalView setYFlipped:NO];
	
	[xReslicedView setOrigin: NSMakePoint( 0, 0)];
	[xReslicedView scaleToFit];
	[xReslicedView setWLWW:[[originalView curDCM] savedWL] :[[originalView curDCM] savedWW]];
//	[xReslicedView setRotation: 0];
//	[xReslicedView setXFlipped:NO];
//	[xReslicedView setYFlipped:NO];
		
	[yReslicedView setOrigin: NSMakePoint( 0, 0)];
	[yReslicedView scaleToFit];
	[yReslicedView setWLWW:[[originalView curDCM] savedWL] :[[originalView curDCM] savedWW]];
//	[yReslicedView setRotation: 0];
//	[yReslicedView setXFlipped:NO];
//	[yReslicedView setYFlipped:NO];

	[self applyOrientation];
}

- (void) scrollTool: (long) from : (long) to : (id) sender
{
	long x, y, max, xStart, yStart;
	if ([sender isEqual: originalView])
	{
		max = [[xReslicedView curDCM] pheight];
		x = [xReslicedView crossPositionX];
		y = xReslicedCrossPositionY+(from-to);
		if ( y < 0) y = 0;
		if ( y >= max) y = max-1;
		[xReslicedView setCrossPosition:x :y];
	}
	else if ([sender isEqual: xReslicedView])
	{
		max = [[originalView curDCM] pheight];
		x = [originalView crossPositionX];
		y = originalCrossPositionY+(from-to);
		if ( y < 0) y = 0;
		if ( y >= max) y = max-1;
		[originalView setCrossPosition:x :y];
	}
	else if ([sender isEqual: yReslicedView])
	{
		max = [[originalView curDCM] pwidth];
		x = originalCrossPositionX+(from-to);
		y = [originalView crossPositionY];
		if ( x < 0) x = 0;
		if ( x >= max) x = max-1;
		[originalView setCrossPosition:x :y];
	}
}

- (void) saveCrossPositions
{
	originalCrossPositionX = [originalView crossPositionX];
	originalCrossPositionY = [originalView crossPositionY];
	xReslicedCrossPositionX = [xReslicedView crossPositionX];
	xReslicedCrossPositionY = [xReslicedView crossPositionY];
	yReslicedCrossPositionX = [yReslicedView crossPositionX];
	yReslicedCrossPositionY = [yReslicedView crossPositionY];
}

- (void) restoreCrossPositions
{
	[originalView setCrossPosition: originalCrossPositionX : originalCrossPositionY];
	[xReslicedView setCrossPosition: xReslicedCrossPositionX : xReslicedCrossPositionY];
	[yReslicedView setCrossPosition: yReslicedCrossPositionX : yReslicedCrossPositionY];
}

- (void) toggleDisplayResliceAxes: (id) sender
{
	if([sender isEqualTo:viewer])
	{
		[originalView toggleDisplayResliceAxes];
		[xReslicedView toggleDisplayResliceAxes];
		[yReslicedView toggleDisplayResliceAxes];
	}
	else
	{
		[viewer toggleDisplayResliceAxes];
	}
}
- (void) displayResliceAxes: (long) boo
{
	[originalView displayResliceAxes:boo];
	[xReslicedView displayResliceAxes:boo];
	[yReslicedView displayResliceAxes:boo];
}

- (void) doubleClick:(NSEvent *)event:(id) sender
{
	[self fullWindowView: sender];
}

- (void) fullWindowView: (id) sender
{
	OrthogonalMPRViewer *mprViewer = viewer;
	
	if ([sender isEqual: originalView])
	{
		[mprViewer fullWindowView: 0];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[mprViewer fullWindowView: 1];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[mprViewer fullWindowView: 2];
	}
}

- (void) saveViewsFrame
{
	originalViewFrame = [originalView frame];
	xReslicedViewFrame = [xReslicedView frame];
	yReslicedViewFrame = [yReslicedView frame];
}

- (void) restoreViewsFrame
{
	[originalView setFrame:originalViewFrame];
	[xReslicedView setFrame:xReslicedViewFrame];
	[yReslicedView setFrame:yReslicedViewFrame];
}

- (void) scaleToFit
{
	[originalView scaleToFit];
}

- (void) scaleToFit : (id) destination
{
	[destination scaleToFit];
}

- (void) saveScaleValue
{
	[originalView saveScaleValue];
	[xReslicedView saveScaleValue];
	[yReslicedView saveScaleValue];
}

- (void) restoreScaleValue
{
	[originalView restoreScaleValue];
	[xReslicedView restoreScaleValue];
	[yReslicedView restoreScaleValue];
}

-(void) refreshViews;
{
	[self saveCrossPositions];
	[self reslice:originalCrossPositionX :originalCrossPositionY :originalView];
}

#pragma mark-
#pragma mark Thick Slab

-(short) thickSlabMode
{
	return thickSlabMode;
}

-(void) setThickSlabMode : (short) newThickSlabMode
{
	if(thickSlabMode == newThickSlabMode)
		return;
	thickSlabMode = newThickSlabMode;
	[self setFusion];
}

-(short) thickSlab
{
	return thickSlab;
}

-(long) maxThickSlab
{
	return [originalDCMPixList count];
}

-(float) thickSlabDistance
{
	return fabs([[originalDCMPixList objectAtIndex:0] sliceInterval]);
}

-(void) setThickSlab : (short) newThickSlab
{
	thickSlab = newThickSlab;
	[reslicer setThickSlab : newThickSlab];
	[self setFusion];
}

-(void) setFusion
{
	long originalThickSlab, xReslicedThickSlab, yReslicedThickSlab;
	originalThickSlab = thickSlab;
	
	xReslicedThickSlab = ((float)thickSlab * [self thickSlabDistance] / [[originalView curDCM] pixelSpacingY]);
	yReslicedThickSlab = ((float)thickSlab * [self thickSlabDistance] / [[originalView curDCM] pixelSpacingX]);
	
	[originalView setFusion:thickSlabMode :originalThickSlab];
	[originalView setThickSlabXY : xReslicedThickSlab : yReslicedThickSlab];
	
	[reslicer setThickSlab : xReslicedThickSlab];
	
	[xReslicedView setFusion:thickSlabMode :xReslicedThickSlab];
	[xReslicedView setThickSlabXY : yReslicedThickSlab : thickSlab];
	
	[yReslicedView setFusion:thickSlabMode :yReslicedThickSlab];
	[yReslicedView setThickSlabXY : xReslicedThickSlab : thickSlab];
	
	[self saveCrossPositions];
	[self reslice:originalCrossPositionX :originalCrossPositionY :originalView];
	
	[[NSUserDefaults standardUserDefaults] setInteger:thickSlab forKey:@"stackThicknessOrthoMPR"];
}

#pragma mark-
#pragma mark NSWindow related methods

- (void) showViews:(id)sender
{
	// Set the 1st view
	[originalView setPixList:originalDCMPixList :originalDCMFilesList:originalROIList];
	[originalView setIndexWithReset:[originalDCMPixList count]/2 :YES];

	DCMPix	*pix = [[originalView pixList] objectAtIndex:0];

	sign = ([pix sliceInterval] >= 0)? 1.0 : -1.0;
	
	// orthogonal reslice
	long x, y; // coordinate of the reslice
	DCMPix *firstDCMPix = [originalDCMPixList objectAtIndex:0];
	x = [firstDCMPix pwidth]/2;
	y = [firstDCMPix pheight]/2;
	
	[originalView setCrossPositionX:x];
	[originalView setCrossPositionY:y];
	[self reslice:x:y:originalView];
}


#pragma mark-
#pragma mark accessors

- (OrthogonalReslice*) reslicer
{
	return reslicer;
}

-(void)setReslicer:(OrthogonalReslice*)newReslicer;
{
	if(reslicer) [reslicer release];
	reslicer = newReslicer;
	[reslicer retain];
}

- (NSMutableArray*) originalDCMPixList
{
	return originalDCMPixList;
}

- (DCMPix*) firtsDCMPixInOriginalDCMPixList
{
	return [originalDCMPixList objectAtIndex:0];
}

- (NSMutableArray*) originalDCMFilesList
{
	return originalDCMFilesList;
}

- (OrthogonalMPRView*) originalView
{
	return originalView;
}

- (OrthogonalMPRView*) xReslicedView
{
	return xReslicedView;
}

- (OrthogonalMPRView*) yReslicedView
{
	return yReslicedView;
}

- (id) viewer
{
	return viewer;
}

- (float) sign
{
	return sign;
}

#pragma mark-
#pragma mark Tools Selection

- (void) setCurrentTool:(short) newTool
{
	[originalView setCurrentTool: newTool];
	[xReslicedView setCurrentTool: newTool];
	[yReslicedView setCurrentTool: newTool];
}

#pragma mark-
#pragma mark ROIs

- (NSMutableArray*) pointsROIAtX: (long) x
{
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtX = [NSMutableArray arrayWithCapacity:0];

	int i, j;
	for(i=0; i<[rois count]; i++)
	{
		for(j=0; j<[[rois objectAtIndex:i] count]; j++)
		{
			ROI *aROI = [[rois objectAtIndex:i] objectAtIndex:j];
			if([aROI type]==t2DPoint)
			{
				if((long)([[[aROI points] objectAtIndex:0] x])==x)
				{
					ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] y];
					long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
					irect.origin.y = sliceIndex; // i is slice number
					irect.size.width = irect.size.height = 0;
					[new2DPointROI setROIRect:irect];
					[new2DPointROI setParentROI:aROI];
					// copy the name
					[new2DPointROI setName:[aROI name]];
					// add the 2D Point ROI to the ROI list
					[roisAtX addObject:new2DPointROI];
				}
			}
		}
	}
	
	return roisAtX;
}

- (NSMutableArray*) pointsROIAtY: (long) y
{
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtY = [NSMutableArray arrayWithCapacity:0];

	int i, j;
	for(i=0; i<[rois count]; i++)
	{
		for(j=0; j<[[rois objectAtIndex:i] count]; j++)
		{
			ROI *aROI = [[rois objectAtIndex:i] objectAtIndex:j];
			if([aROI type]==t2DPoint)
			{
				if((long)([[[aROI points] objectAtIndex:0] y])==y)
				{
					ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[xReslicedView pixelSpacingX] :[xReslicedView pixelSpacingY] :NSMakePoint( [xReslicedView origin].x, [xReslicedView origin].y)];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] x];
					long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
					irect.origin.y = sliceIndex;
					irect.size.width = irect.size.height = 0;
					[new2DPointROI setROIRect:irect];
					[new2DPointROI setParentROI:aROI];
					// copy the name
					[new2DPointROI setName:[aROI name]];
					// add the 2D Point ROI to the ROI list
					[roisAtY addObject:new2DPointROI];
				}
			}
		}
	}
	
	return roisAtY;
}

- (void) loadROIonXReslicedView: (long) y
{
	[xReslicedView setCurRoiList:[self pointsROIAtY:y]];
	[xReslicedView setNeedsDisplay:YES];
}

- (void) loadROIonYReslicedView: (long) x
{
	[yReslicedView setCurRoiList:[self pointsROIAtX:x]];
	[yReslicedView setNeedsDisplay:YES];
}

- (void) loadROIonReslicedViews: (long) x: (long) y
{
	[self loadROIonXReslicedView: y];
	[self loadROIonYReslicedView: x];
}


- (NSMenu *)contextualMenu{

// if contextualMenuPath says @"default", recreate the default menu once and again
// if contextualMenuPath contains a path, create the new contextual menu
// if contextualMenuPath says @"custom", don't do anything

	NSMenu *contextual;
		//if([contextualDictionaryPath isEqualToString:@"default"]) // JF20070102
		{
			/******************* Tools menu ***************************/
			contextual =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
			NSMenu *submenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"ROI", nil)];
			NSMenuItem *item;
			NSArray *titles = [NSArray arrayWithObjects:NSLocalizedString(@"Contrast", nil), NSLocalizedString(@"Move", nil), NSLocalizedString(@"Magnify", nil), 
														NSLocalizedString(@"Rotate", nil), NSLocalizedString(@"Scroll", nil), NSLocalizedString(@"ROI", nil), nil];
			NSArray *images = [NSArray arrayWithObjects: @"WLWW", @"Move", @"Zoom",  @"Rotate",  @"Stack", @"Length", nil];	// DO NOT LOCALIZE THIS LINE ! -> filenames !
			NSEnumerator *enumerator = [titles objectEnumerator];
			NSEnumerator *enumerator2 = [images objectEnumerator];
			//NSEnumerator *enumerator3 = [[popupRoi itemArray] objectEnumerator];
			NSString *title;
			NSString *image;
			NSMenuItem *subItem;
			int i = 0;
			/*
			[enumerator3 nextObject];	// First item is pop main menu
			while (subItem = [enumerator3 nextObject])
			{
				int tag = [subItem tag];
				item = [[NSMenuItem alloc] initWithTitle: [subItem title] action: @selector(setROITool:) keyEquivalent:@""];
				[item setTag:tag];
				[item setImage: [self imageForROI: tag]];
				[item setTarget:self];
				[submenu addItem:item];
				[item release];
			}
			*/
			while (title = [enumerator nextObject]) {
				image = [enumerator2 nextObject];
				item = [[NSMenuItem alloc] initWithTitle: title action: @selector(setDefaultTool:) keyEquivalent:@""];
				[item setTag:i++];
				[item setTarget:self];
				[item setImage:[NSImage imageNamed:image]];
				[contextual addItem:item];
				[item release];
			}
			[[contextual itemAtIndex:5] setSubmenu:submenu];
			
			[contextual addItem:[NSMenuItem separatorItem]];
			
			/******************* WW/WL menu items **********************/
			NSMenu *mainMenu = [NSApp mainMenu];
			NSMenu *viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
			NSMenu *fileMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"File", nil)] submenu];
			NSMenu *presetsMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
			NSMenu *menu = [presetsMenu copy];
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Window Width & Level", nil) action: nil keyEquivalent:@""];
			[item setSubmenu:menu];
			[contextual addItem:item];
			[item release];
			[menu release];
			
			[contextual addItem:[NSMenuItem separatorItem]];
			
			/************* window resize Menu ****************/
			
			[submenu release];
			submenu =  [[NSMenu alloc] initWithTitle:@"Resize window"];
			
			NSArray *resizeWindowArray = [NSArray arrayWithObjects:@"25%", @"50%", @"100%", @"200%", @"300%", @"iPod Video", nil];
			NSEnumerator *resizeEnumerator = [resizeWindowArray objectEnumerator];
			i = 0;
			NSString	*titleMenu;
			while (titleMenu = [resizeEnumerator nextObject]) {
				int tag = i++;
				item = [[NSMenuItem alloc] initWithTitle:titleMenu action: @selector(resizeWindow:) keyEquivalent:@""];
				[item setTag:tag];
				//[item setTarget:imageView];
				[submenu addItem:item];
				[item release];
			}
			
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Resize window", nil) action: nil keyEquivalent:@""];
			[item setSubmenu:submenu];
			[contextual addItem:item];
			[item release];
			
			[contextual addItem:[NSMenuItem separatorItem]];
			
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Actual size", nil) action: @selector(actualSize:) keyEquivalent:@""];
			[contextual addItem:item];
			[item release];
			
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Key image", nil) action: @selector(setKeyImage:) keyEquivalent:@""];
			[contextual addItem:item];
			[item release];
			
			// Tiling
			NSMenu *tilingMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Image Tiling", nil)] submenu];
			menu = [tilingMenu copy];
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Image Tiling", nil) action: nil keyEquivalent:@""];
			[item setSubmenu:menu];
			[contextual addItem:item];
			[item release];
			[menu release];

			/********** Orientation submenu ************/ 
			
			NSMenu *orientationMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Orientation", nil)] submenu];
			menu = [orientationMenu copy];
			for( i = 0; i < [menu numberOfItems]; i++) [[menu itemAtIndex: i] setState: NSOffState];
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Orientation", nil) action: nil keyEquivalent:@""];
			[item setSubmenu:menu];
			[contextual addItem:item];
			[item release];
			[menu release];

			//Export Added 12/5/05
			/*************Export submenu**************/
			NSMenu *exportMenu = [[fileMenu itemWithTitle:NSLocalizedString(@"Export", nil)] submenu];
			menu = [exportMenu copy];
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil keyEquivalent:@""];
			[item setSubmenu:menu];
			[contextual addItem:item];
			[item release];
			[menu release];
			
			[contextual addItem:[NSMenuItem separatorItem]];
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open database", nil) action: @selector(databaseWindow:)  keyEquivalent:@""];
			[item setTarget:self];
			[contextual addItem:item];
			[item release];

			[submenu release];
	}
	/*
	else //use the menuDictionary of the path JF20070102
	{
		   NSArray *pathComponents = [[self contextualDictionaryPath] pathComponents];
		   NSString *plistTitle = [[pathComponents objectAtIndex:([pathComponents count]-1)] stringByDeletingPathExtension];
		   contextual = [[NSMenu alloc] initWithTitle:plistTitle
											   withDictionary:[NSDictionary dictionaryWithContentsOfFile:[self contextualDictionaryPath]]
										  forWindowController:self ];
		   
	}
	*/
	
	return [contextual autorelease];
}


@end
