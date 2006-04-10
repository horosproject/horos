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
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

#import "ROI.h"

@implementation OrthogonalMPRController

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC:(id) newViewer
{
	// initialisations
	originalDCMPixList = [pix retain];
	originalDCMFilesList = [[NSMutableArray alloc] initWithArray:files];
	
	originalROIList = [[[vC imageView] dcmRoiList] retain];	//<- Isn't Wrong??? Why this? It crashes PET-CT
	
	reslicer = [[OrthogonalReslice alloc] initWithOriginalDCMPixList: originalDCMPixList];
		
	// Set the views (OrthogonalMPRView)
	[originalView setController:self];
	[xReslicedView setController:self];
	[yReslicedView setController:self];
		
	[originalView setCurrentTool:tCross];	
	[xReslicedView setCurrentTool:tCross];
	[yReslicedView setCurrentTool:tCross];
	
	viewer = newViewer;
	
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(changeWLWW:)
											name: @"changeWLWW"
											object: nil];

//	[[NSNotificationCenter defaultCenter]	addObserver: self
//											selector: @selector(addROI:)
//											name: @"addROI"
//											object: nil];
													
//	[[NSNotificationCenter defaultCenter]	addObserver: self
//											selector: @selector(roiChange:)
//											name: @"roiChange"
//											object: nil];
			 
//	[[NSNotificationCenter defaultCenter]	addObserver: self
//											selector: @selector(roiSelected:)
//											name: @"roiSelected"
//											object: nil];
			 
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

#pragma mark-
#pragma mark Orthogonal reslice methods


- (void) reslice: (long) x: (long) y: (OrthogonalMPRView*) sender
{
//	originalROIList = [[originalView dcmRoiList] retain];
	
	//NSLog(@"reslice: %d, %d", x, y);
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
		
//		NSLog(@"yReslicedView setCurRoiList");
//		[yReslicedView setCurRoiList:[self pointsROIAtX:x]];
//		NSLog(@"xReslicedView setCurRoiList");
//		[xReslicedView setCurRoiList:[self pointsROIAtY:y]];
		
		[xReslicedView setPixList : xReslicedDCMPixList :originalDCMFilesList];
		[yReslicedView setPixList : yReslicedDCMPixList :originalDCMFilesList];
		
		// WLWW
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
			
//			NSLog(@"yReslicedView setCurRoiList");
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
			
//			NSLog(@"xReslicedView setCurRoiList");
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
	
	// needs display
	[originalView setNeedsDisplay:YES];
	[xReslicedView setNeedsDisplay:YES];
	[yReslicedView setNeedsDisplay:YES];
}

-(void) flipVolume
{
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
	[originalView setOrigin: [sender origin]];
	[originalView setOriginOffset: [sender originOffset]];
	
	NSPoint		pt;
	
	// X - Views
	
	pt.y = [xReslicedView origin].y;
	pt.x = [sender origin].x;
	[xReslicedView setOrigin: pt];

	pt.y = [xReslicedView originOffset].y;
	pt.x = [sender originOffset].x;
	[xReslicedView setOriginOffset: pt];

	// Y - Views
	
	pt.y = [yReslicedView origin].y;
	pt.x = -[sender origin].y;
	[yReslicedView setOrigin: pt];

	pt.y = [yReslicedView originOffset].y;
	pt.x = -[sender originOffset].y;
	[yReslicedView setOriginOffset: pt];
}

- (void) blendingPropagateX:(OrthogonalMPRView*) sender
{
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[xReslicedView setScaleValue: fValue * [xReslicedView pixelSpacing]];
	[xReslicedView setRotation: [sender rotation]];
	[xReslicedView setOrigin: [sender origin]];
	[xReslicedView setOriginOffset: [sender originOffset]];
	
	NSPoint		pt;
	
	// X - Views
	
	pt.y = [originalView origin].y;
	pt.x = [sender origin].x;
	[originalView setOrigin: pt];

	pt.y = [originalView originOffset].y;
	pt.x = [sender originOffset].x;
	[originalView setOriginOffset: pt];

	// Y - Views
	
	pt.x = [yReslicedView origin].x;
	pt.y = [sender origin].y;
	[yReslicedView setOrigin: pt];

	pt.x = [yReslicedView originOffset].x;
	pt.y = [sender originOffset].y;
	[yReslicedView setOriginOffset: pt];
}

- (void) blendingPropagateY:(OrthogonalMPRView*) sender
{
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[yReslicedView setScaleValue: fValue * [yReslicedView pixelSpacing]];
	[yReslicedView setRotation: [sender rotation]];
	[yReslicedView setOrigin: [sender origin]];
	[yReslicedView setOriginOffset: [sender originOffset]];
	
	NSPoint		pt;
	
	// X - Views
	
	pt.x = [originalView origin].x;
	pt.y = -[sender origin].x;
	[originalView setOrigin: pt];

	pt.x = [originalView originOffset].x;
	pt.y = -[sender originOffset].x;
	[originalView setOriginOffset: pt];

	// Y - Views
	
	pt.x = [xReslicedView origin].x;
	pt.y = [sender origin].y;
	[xReslicedView setOrigin: pt];

	pt.x = [xReslicedView originOffset].x;
	pt.y = [sender originOffset].y;
	[xReslicedView setOriginOffset: pt];
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
	[xReslicedView adjustScaleValue: x];
	[yReslicedView adjustScaleValue: x];
}

- (void) resetImage
{
	[originalView setOrigin: NSMakePoint( 0, 0)];
	[originalView scaleToFit];
	[originalView setRotation: 0];
	[originalView setWLWW:[[originalView curDCM] savedWL] :[[originalView curDCM] savedWW]];
	[originalView setXFlipped:NO];
	[originalView setYFlipped:NO];
	
	[xReslicedView setOrigin: NSMakePoint( 0, 0)];
	[xReslicedView scaleToFit];
	[xReslicedView setRotation: 0];
	[xReslicedView setWLWW:[[originalView curDCM] savedWL] :[[originalView curDCM] savedWW]];
	[xReslicedView setXFlipped:NO];
	[xReslicedView setYFlipped:NO];
		
	[yReslicedView setOrigin: NSMakePoint( 0, 0)];
	[yReslicedView scaleToFit];
	[yReslicedView setRotation: 0];
	[yReslicedView setWLWW:[[originalView curDCM] savedWL] :[[originalView curDCM] savedWW]];
	[yReslicedView setXFlipped:NO];
	[yReslicedView setYFlipped:NO];
}

- (void) scrollTool: (long) from : (long) to : (id) sender
{
	long x, y, max, xStart, yStart;
	if ([sender isEqual: originalView])
	{
		max = [[xReslicedView curDCM] pheight];
		x = [xReslicedView crossPositionX];
		y = xReslicedCrossPositionY+(from-to);//*max/([[originalView curDCM] pheight]/2);
		if ( y < 0) y = 0;
		if ( y >= max) y = max-1;
		[xReslicedView setCrossPosition:x :y];
	}
	else if ([sender isEqual: xReslicedView])
	{
		max = [[originalView curDCM] pheight];
		x = [originalView crossPositionX];
		y = originalCrossPositionY+(from-to);//*max/([[xReslicedView curDCM] pheight]/2);
		if ( y < 0) y = 0;
		if ( y >= max) y = max-1;
		[originalView setCrossPosition:x :y];
	}
	else if ([sender isEqual: yReslicedView])
	{
		max = [[originalView curDCM] pwidth];
		x = originalCrossPositionX+(from-to);//*max/([[yReslicedView curDCM] pwidth]/2);
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
	if ([sender isEqual: originalView])
	{
		[viewer fullWindowView:0];
	}
	else if ([sender isEqual: xReslicedView])
	{
		[viewer fullWindowView:1];
	}
	else if ([sender isEqual: yReslicedView])
	{
		[viewer fullWindowView:2];
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

#pragma mark-
#pragma mark Thick Slab

-(short) thickSlabMode
{
	return thickSlabMode;
}

-(void) setThickSlabMode : (short) newThickSlabMode
{
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
	
//	NSLog(@"thickSlabDistance: %f pixelSpacingY: %f",[self thickSlabDistance], [[originalView curDCM] pixelSpacingY]);
	
	xReslicedThickSlab = ((float)thickSlab * [self thickSlabDistance] / [[originalView curDCM] pixelSpacingY]);
	yReslicedThickSlab = ((float)thickSlab * [self thickSlabDistance] / [[originalView curDCM] pixelSpacingX]);
	
	[originalView setFusion:thickSlabMode :originalThickSlab];
	[originalView setThickSlabXY : xReslicedThickSlab : yReslicedThickSlab];
	
//	NSLog(@"axial: %d x: %d y:%d", originalThickSlab, xReslicedThickSlab, yReslicedThickSlab);
	
	[reslicer setThickSlab : xReslicedThickSlab];
	
	[xReslicedView setFusion:thickSlabMode :xReslicedThickSlab];
	[xReslicedView setThickSlabXY : yReslicedThickSlab : thickSlab];
	
	
	[yReslicedView setFusion:thickSlabMode :yReslicedThickSlab];
	[yReslicedView setThickSlabXY : xReslicedThickSlab : thickSlab];
	
	[self saveCrossPositions];
	[self reslice:originalCrossPositionX :originalCrossPositionY :originalView];
}

#pragma mark-
#pragma mark NSWindow related methods

- (void) showViews:(id)sender
{
	// Set the 1st view
	[originalView setPixList:originalDCMPixList :originalDCMFilesList:originalROIList];
	[originalView setIndexWithReset:[originalDCMPixList count]/2 :YES];
	sign = ([[[originalView pixList] objectAtIndex:0] sliceInterval] > 0)? 1.0 : -1.0;
	
//	[originalView setCurRoiList:originalROIList];
//	NSMutableArray *rois = [originalView dcmRoiList];
//	
	//[originalView setCrossPosition:round((float)[[[originalView pixList] objectAtIndex:0] pwidth]*0.5f) :round((float)[[[originalView pixList] objectAtIndex:0] pheight]*0.5f)];
	
	// orthogonal reslice
	long x, y; // coordinate of the reslice
	DCMPix *firstDCMPix = [originalDCMPixList objectAtIndex:0];
	x = [firstDCMPix pwidth]/2;
	y = [firstDCMPix pheight]/2;
	
	[originalView setCrossPositionX:x];
	[originalView setCrossPositionY:y];
	[self reslice:x:y:originalView];
	
	//[originalView setRotation:0];	
	//[xReslicedView setRotation:0];
	//[yReslicedView setRotation:0];
//	xReslicedDCMPixList = [reslicer xReslicedDCMPixList];
//	yReslicedDCMPixList = [reslicer yReslicedDCMPixList];
//	
//	// Display results in the resliced views (OrthogonalMPRView)
//	[xReslicedView setPixList:xReslicedDCMPixList :originalDCMFilesList];
//	[yReslicedView setPixList:yReslicedDCMPixList :originalDCMFilesList];
}


#pragma mark-
#pragma mark accessors

- (OrthogonalReslice*) reslicer
{
	return reslicer;
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
				//NSLog(@"pt : %f, x : %d", [[[aROI points] objectAtIndex:0] x], x);
//				if((long)([[[aROI points] objectAtIndex:0] x]+0.5)==x)
				if((long)([[[aROI points] objectAtIndex:0] x])==x)
				{
					//NSLog(@"pt 2D");
					ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] y];
					long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
					irect.origin.y = sliceIndex; // i is slice number
					irect.size.width = irect.size.height = 0;
					[new2DPointROI setROIRect:irect];
					[new2DPointROI setParentROI:aROI];
					// copy the state
//					[new2DPointROI setROIMode:[aROI ROImode]];
					// copy the name
					[new2DPointROI setName:[aROI name]];
					// add the 2D Point ROI to the ROI list
					[roisAtX addObject:new2DPointROI];
				}
			}
		}
	}
	//NSLog(@"[roisAtX count] : %d", [roisAtX count]);
	
	return roisAtX;
}

- (NSMutableArray*) pointsROIAtY: (long) y
{
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtY = [NSMutableArray arrayWithCapacity:0];

	int i, j;
	for(i=0; i<[rois count]; i++)
	{
		//NSLog(@"i : %d", i);
		for(j=0; j<[[rois objectAtIndex:i] count]; j++)
		{
			//NSLog(@"j : %d", j);
			ROI *aROI = [[rois objectAtIndex:i] objectAtIndex:j];
			if([aROI type]==t2DPoint)
			{
				//NSLog(@"pt 2D");
				//NSLog(@"pt : %f, y : %d", [[[aROI points] objectAtIndex:0] y], y);
//				if((long)([[[aROI points] objectAtIndex:0] y]+0.5)==y)
				if((long)([[[aROI points] objectAtIndex:0] y])==y)
				{
					//NSLog(@"pt 2D");
					ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[xReslicedView pixelSpacingX] :[xReslicedView pixelSpacingY] :NSMakePoint( [xReslicedView origin].x, [xReslicedView origin].y)];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] x];
					long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
					irect.origin.y = sliceIndex;
					irect.size.width = irect.size.height = 0;
					[new2DPointROI setROIRect:irect];
					[new2DPointROI setParentROI:aROI];
					// copy the state
//					[new2DPointROI setROIMode:[aROI ROImode]];
					// copy the name
					[new2DPointROI setName:[aROI name]];
					// add the 2D Point ROI to the ROI list
					[roisAtY addObject:new2DPointROI];
				}
			}
		}
	}
	//NSLog(@"[roisAtY count] : %d", [roisAtY count]);
	
	return roisAtY;
}

- (void) loadROIonReslicedViews: (long) x: (long) y
{
	NSLog(@"loadROIonReslicedViews");
	[xReslicedView setCurRoiList:[self pointsROIAtY:y]];
	[yReslicedView setCurRoiList:[self pointsROIAtX:x]];
//	[xReslicedView setIndex:0];
//	[yReslicedView setIndex:0];
	[xReslicedView setNeedsDisplay:YES];
	[yReslicedView setNeedsDisplay:YES];
}

//-(void) roiSelected:(NSNotification*) note
//{
//	if([[note object] type]==t2DPoint)
//	{
//		[self loadROIonReslicedViews: originalCrossPositionX : originalCrossPositionY];
//	}
//}

//-(void) roiChange:(NSNotification*)note
//{
//	if([[note object] type]==t2DPoint)
//	{
//		[self loadROIonReslicedViews: originalCrossPositionX : originalCrossPositionY];
//	}
//}

//- (void) addROI:(NSNotification*)note
//{
//	//[super addROI:note];
//	
//	NSLog(@"addROI:(NSNotification*)note [OrthogonalMPRController]");
//	DCMView *sender = [note object];
//	ROI *addedROI = [[note userInfo] objectForKey:@"ROI"];
//	int sliceNumber = [[[note userInfo] objectForKey:@"sliceNumber"] intValue];
//	
//	if([addedROI type]==t2DPoint)
//	{
//		if([xReslicedView isEqualTo:sender] || [yReslicedView isEqualTo:sender])
//		{
//			ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[originalView pixelSpacingX] :[originalView pixelSpacingY] :NSMakePoint( [originalView origin].x, [originalView origin].y)];
//
//			NSRect irect;
//			if([xReslicedView isEqualTo:sender])
//			{
//				irect.origin.x = [[[addedROI points] objectAtIndex:0] x];
//				irect.origin.y = [originalView crossPositionY];
//			}
//			else
//			{
//				irect.origin.x = [originalView crossPositionX];
//				irect.origin.y = [[[addedROI points] objectAtIndex:0] x];
//			}			
//			irect.size.width = irect.size.height = 0;
//			[new2DPointROI setROIRect:irect];
//	
//			[originalView roiSet:new2DPointROI];
//			// add the 2D Point ROI to the ROI list
//			long slice = (sign>0)? [[originalView dcmPixList] count]-1 -[[[addedROI points] objectAtIndex:0] y] : [[[addedROI points] objectAtIndex:0] y];
//			[[[originalView dcmRoiList] objectAtIndex: slice] addObject: new2DPointROI];
//		}
//		[self loadROIonReslicedViews: [originalView crossPositionX] : [originalView crossPositionY]];
//	}
//	
////	if (![self isEqualTo:sender])
////	{
////		NSLog(@"sender is not self");
////		if ([[controller originalView] isEqualTo:sender])
////		{
////			NSLog(@"sender is originalView");
////			if([addedROI type]==t2DPoint)
////			{
////				ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[self pixelSpacingX] :[self pixelSpacingY] :NSMakePoint( [self origin].x, [self origin].y)];
////				NSRect irect;
////				
////				if([self isEqualTo:[controller xReslicedView]])
////				{
////					irect.origin.x = [[[addedROI points] objectAtIndex:0] x];
////				}
////				else
////				{
////					irect.origin.x = [[[addedROI points] objectAtIndex:0] y];
////				}
////				
////				long sliceIndex = ([controller sign]>0)? [[[controller originalView] dcmPixList] count]-1 -sliceNumber : sliceNumber; // i is slice number
////				irect.origin.y = sliceIndex;
////				irect.size.width = irect.size.height = 0;
////				[new2DPointROI setROIRect:irect];
////				[self roiSet:new2DPointROI];
////				// add the 2D Point ROI to the ROI list
////				[[dcmRoiList objectAtIndex: 0] addObject: new2DPointROI];
////				// no notification !!! or loop and die!
////			}
////		}
////		else if ([[controller xReslicedView] isEqualTo:sender] || [[controller yReslicedView] isEqualTo:sender])
////		{
////			NSLog(@"sender is xReslicedView OR yReslicedView");
////			if([addedROI type]==t2DPoint)
////			{
////				// remove point on sender
////				
////				// add pt on self (which is original)
////				
////				// notify (will add the point to xresliced an yresliced)
////				
////			}
////		}
////		else if([[self dcmPixList] isEqualTo:[sender dcmPixList]])
////		{
////			NSLog(@"[[self dcmPixList] isEqualTo:[sender dcmPixList]]");
////			[self roiSet:addedROI];
////			NSLog(@"[dcmRoiList count] : %d", [dcmRoiList count]);
////			[[dcmRoiList objectAtIndex: sliceNumber] addObject: addedROI];
////			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:addedROI userInfo: 0L];
////		}
////	}
//}

@end
