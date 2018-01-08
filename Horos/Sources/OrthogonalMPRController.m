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

#import "OrthogonalMPRController.h"
#import "OrthogonalMPRViewer.h"
#import "OpacityTransferView.h"
#import "Notifications.h"
#import "AppController.h"

#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

#import "ROI.h"

@interface OrthogonalMPRController (Dummy)

- (void)resizeWindow:(id)dummy;

@end

@implementation OrthogonalMPRController

@synthesize orientationVector;

- (void) setCrossPosition: (float) x : (float) y : (id) sender
{
    [self reslice: x:  y: sender];
}

-(void) setBlendingFactor:(float) f
{
}

- (void) applyOrientation
{
	switch( orientationVector)
	{
		case eSagittalPos:
		case eSagittalNeg:
			[xReslicedView setXFlipped: YES];
			if( [xReslicedView rotation] == 0) [xReslicedView setRotation: 90];
			
			[yReslicedView setXFlipped: YES];
			if( [yReslicedView rotation] == 0) [yReslicedView setRotation: 90];
		break;
		
		case eCoronalPos:
		case eCoronalNeg:
			[xReslicedView setYFlipped: YES];
			if( [yReslicedView rotation] == 0) [yReslicedView setRotation: 90];
		break;
		
		case eAxialPos:
		break;
		
		case eAxialNeg: 
			[xReslicedView setYFlipped: YES];
			[yReslicedView setYFlipped: YES];
		break;
		
		default:
			NSLog( @"Orientation Unknown: %d", (int) orientationVector);
		break;
	}
}

- (void) setPixList: (NSArray*)pix :(NSArray*)files :(ViewerController*)vC
{
	if( originalDCMPixList) [originalDCMPixList removeAllObjects];
	else originalDCMPixList = [[NSMutableArray alloc] initWithCapacity: [pix count]];
	
	for( DCMPix *p in pix)
		[originalDCMPixList addObject:  [[p copy] autorelease]];
	
	[originalDCMFilesList release];
	originalDCMFilesList = [[NSMutableArray alloc] initWithArray:files];

	if( [vC blendingController] == nil)
	{
		[originalROIList release];
		originalROIList = [[[vC imageView] dcmRoiList] retain];
	}
	else
	{
		originalROIList = nil;
	}

	[reslicer release];
	reslicer = [[OrthogonalReslice alloc] initWithOriginalDCMPixList: originalDCMPixList];
}

- (id) initWithPixList: (NSArray*)pix :(NSArray*)files :(NSData*)vData :(ViewerController*)vC :(ViewerController*)bC :(id)newViewer
{
	if (self = [super init])
	{
		// initialisations
		[self setPixList: pix :files : vC];
		
		// Set the views (OrthogonalMPRView)
		[originalView setController:self];
		[xReslicedView setController:self];
		[yReslicedView setController:self];
			
		[originalView setCurrentTool:tCross];	
		[xReslicedView setCurrentTool:tCross];
		[yReslicedView setCurrentTool:tCross];
		
		viewerController = vC;
		
		viewer = newViewer;
		[originalView  setMenu:[self contextualMenu]];
		[xReslicedView setMenu:[self contextualMenu]];
		[yReslicedView setMenu:[self contextualMenu]];
		
		[[NSNotificationCenter defaultCenter]	addObserver: self
												selector: @selector(changeWLWW:)
												name: OsirixChangeWLWWNotification
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
	
	[transferFunction release];
	[originalDCMPixList release];
	[originalDCMFilesList release];
	
	[originalROIList release];
	
	[reslicer release];
	
	[super dealloc];
}

#pragma mark-
#pragma mark Orthogonal reslice methods


- (void) reslice: (long) x : (long) y : (OrthogonalMPRView*) sender
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
		float wl = 0, ww = 0;
        [originalView getWLWW:&wl :&ww];
        
        if( wl != 0 && ww != 0)
        { 
            [xReslicedView adjustWLWW:wl :ww];
            [yReslicedView adjustWLWW:wl :ww];
		}
        
		// move cross on the other views
		[xReslicedView setCrossPositionX:x+0.5];
		[yReslicedView setCrossPositionX:y+0.5];
		NSInteger sliceIndex = [[originalView pixList] indexOfObject:[originalView curDCM]] + [[originalView curDCM] stack]/2;
		NSInteger h = (sign>0)? [[originalView dcmPixList] count]-sliceIndex-1 : sliceIndex ;

		[xReslicedView setCrossPositionY:h+0.5];
		[yReslicedView setCrossPositionY:h+0.5];
	}
	else
	{
		int stackCount = [[originalView dcmPixList] count];
		
//		stackCount /= 2;
//		stackCount *= 2;
		
		// slice index on axial view
		int sliceIndex = (sign>0)? stackCount-1 -y : y;
		
		sliceIndex = sliceIndex - thickSlab/2;
		
		if( sliceIndex < 0) sliceIndex = 0;
		if( sliceIndex >= stackCount) sliceIndex = stackCount-1;
		// update axial view
		[originalView setIndex:sliceIndex];
		
		if ([sender isEqual: xReslicedView])
		{
			[originalView setCrossPositionX:x+0.5];
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
			[yReslicedView setCrossPositionY:y+0.5];
		}
		else if ([sender isEqual: yReslicedView])
		{
			[originalView setCrossPositionY:x+0.5];
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
			[xReslicedView setCrossPositionY:y+0.5];
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
	
	int i;
	
	for( i = 0 ; i < [yReslicedDCMPixList count]; i++)
		[[yReslicedDCMPixList objectAtIndex: i] setTransferFunction: transferFunction];

	for( i = 0 ; i < [originalDCMPixList count]; i++)
		[[originalDCMPixList objectAtIndex: i] setTransferFunction: transferFunction];

	for( i = 0 ; i < [xReslicedDCMPixList count]; i++)
		[[xReslicedDCMPixList objectAtIndex: i] setTransferFunction: transferFunction];
	
	[originalView updateImage];
	[xReslicedView updateImage];
	[yReslicedView updateImage];
	
	// needs display
	[originalView setNeedsDisplay:YES];
	[xReslicedView setNeedsDisplay:YES];
	[yReslicedView setNeedsDisplay:YES];
}

- (void) setTransferFunction:(NSData*) tf
{
	if( tf != transferFunction)
	{
		[transferFunction release];
		transferFunction = [tf retain];
	}
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
	double fValue = [sender scaleValue] / [sender pixelSpacing];
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
	double fValue = [sender scaleValue] / [sender pixelSpacing];
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
	double fValue = [sender scaleValue] / [sender pixelSpacing];
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

-(void) ApplyOpacityString:(NSString*) str
{
	NSDictionary		*aOpacity;
	
	if( [str isEqualToString:NSLocalizedString(@"Linear Table", nil)])
	{
		[self setTransferFunction: nil];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if (aOpacity)
		{
//			array = [aOpacity objectForKey:@"Points"];
			
			[self setTransferFunction: [OpacityTransferView tableWith4096Entries: [aOpacity objectForKey:@"Points"]]];
		}
	}
}

-(void) ApplyCLUTString:(NSString*) str
{
	if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)])
	{
		[originalView setCLUT: nil :nil :nil];
		[xReslicedView setCLUT: nil :nil :nil];
		[yReslicedView setCLUT: nil :nil :nil];
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
	[viewerController setWL: iwl WW: iww];
	
	[originalView adjustWLWW: iwl : iww];
	[xReslicedView adjustWLWW: iwl : iww];
	[yReslicedView adjustWLWW: iwl : iww];
	[self setCurWLWWMenu: NSLocalizedString(@"Other", nil)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixChangeWLWWNotification object: [originalView curDCM] userInfo:nil];
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
	long x, y, max;
	if ([sender isEqual: originalView])
	{
		max = [[xReslicedView curDCM] pheight];
		x = [xReslicedView crossPositionX];
		y = xReslicedCrossPositionY+(from-to);
		if ( y < 0) y = 0;
		if ( y >= max) y = max-1;
		[xReslicedView setCrossPosition:x+0.5 :y+0.5];
	}
	else if ([sender isEqual: xReslicedView])
	{
		max = [[originalView curDCM] pheight];
		x = [originalView crossPositionX];
		y = originalCrossPositionY+(from-to);
		if ( y < 0) y = 0;
		if ( y >= max) y = max-1;
		[originalView setCrossPosition:x+0.5 :y+0.5];
	}
	else if ([sender isEqual: yReslicedView])
	{
		max = [[originalView curDCM] pwidth];
		x = originalCrossPositionX+(from-to);
		y = [originalView crossPositionY];
		if ( x < 0) x = 0;
		if ( x >= max) x = max-1;
		[originalView setCrossPosition:x+0.5 :y+0.5];
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

#pragma mark-

- (void) notifyPositionChange
{
    float* originPos = [viewer syncOriginPosition];
    
    if( originPos)
    {
        float currentLocation[3] ;
        [OrthogonalMPRViewer getDICOMCoords:viewer :currentLocation];

        NSMutableArray* newPosition =[NSMutableArray arrayWithCapacity:3];
        
        for(int i =0 ;i<3 ;i++)
            [newPosition addObject:[NSNumber numberWithFloat:currentLocation[i]-originPos[i]]];
        
        [OrthogonalMPRViewer positionChange:viewer :newPosition];
    }
}

- (void) moveToRelativePosition:(NSArray*) relativeDicomLocation
{
    float* originPos = [viewer syncOriginPosition];

    NSMutableArray* newLocation =[NSMutableArray arrayWithCapacity:3];
    
    [relativeDicomLocation enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        [newLocation insertObject:[NSNumber numberWithFloat:[obj floatValue] + originPos[idx]] atIndex:idx ];
    }];
    
    [self moveToAbsolutePosition:newLocation];
}

- (void) moveToAbsolutePosition:(NSArray*) newDicomLocation
{
    float dcmCoord[3];
    float sliceCoord[3];
    
    for(int i=0 ; i<3;i++)
        dcmCoord[i] =  [[newDicomLocation objectAtIndex:i]floatValue];
    
    [[originalView curDCM] convertDICOMCoords:dcmCoord toSliceCoords:sliceCoord pixelCenter:YES];
    sliceCoord[ 0] /= [[originalView curDCM] pixelSpacingX];
    sliceCoord[ 1] /= [[originalView curDCM] pixelSpacingY];
    sliceCoord[ 2] /= [[originalView curDCM] sliceInterval];
    //    NSLog(@"moveToAbsolutePosition - sliceCoord : %f %f index : %f", sliceCoord[0], sliceCoord[1], sliceCoord[2]);
    
    [originalView setCrossPosition:sliceCoord[0] :sliceCoord[1] withNotification:FALSE];
    
    [[xReslicedView curDCM] convertDICOMCoords:dcmCoord toSliceCoords:sliceCoord pixelCenter:YES];
    sliceCoord[ 0] /= [[xReslicedView curDCM] pixelSpacingX];
    sliceCoord[ 1] /= [[xReslicedView curDCM] pixelSpacingY];
    sliceCoord[ 2] /= [[xReslicedView curDCM] sliceInterval];
    //    NSLog(@"moveToAbsolutePosition - sliceCoord : %f %f index : %f", sliceCoord[0], sliceCoord[1], sliceCoord[2]);
    
    [xReslicedView setCrossPosition:sliceCoord[0] :sliceCoord[1] withNotification:FALSE];
}

#pragma mark-

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

- (void) doubleClick:(NSEvent *)event :(id) sender
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
	[originalView setThickSlabXY : xReslicedThickSlab : yReslicedThickSlab / [[originalView curDCM] pixelRatio]];
	
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
	
	[originalView setCrossPositionX:x+0.5];
	[originalView setCrossPositionY:y+0.5];
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

- (void) setCurrentTool:(ToolMode) newTool
{
	[originalView setCurrentTool: newTool];
	[xReslicedView setCurrentTool: newTool];
	[yReslicedView setCurrentTool: newTool];
}

- (int) currentTool
{
	return [originalView currentTool];
}

#pragma mark-
#pragma mark ROIs

- (NSMutableArray*) pointsROIAtX: (long) x
{
    NSMutableDictionary *plainDict = [NSMutableDictionary dictionary];
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtX = [NSMutableArray array];
    
    int imageWidth = [[[yReslicedView pixList] lastObject] pwidth];
    int imageHeight = [[[yReslicedView pixList] lastObject] pheight];
    
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
					ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] y];
					long sliceIndex = (sign>0)? (long)[[originalView dcmPixList] count]-1 -i : i; // i is slice number
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
            
            if( [aROI type] == tPlain)
            {
                if( x >= aROI.textureUpLeftCornerX && x < aROI.textureDownRightCornerX)
                {
                    if( [plainDict objectForKey: [aROI name]] == nil)
                    {
                        unsigned char* t = calloc( imageWidth * imageHeight, sizeof(unsigned char));
                        
                        if( t)
                        {
                            ROI *newROI = [[[ROI alloc] initWithType: tPlain :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
                            
                            newROI.name = [aROI name];
                            newROI.thickness = aROI.thickness;
                            newROI.rgbcolor = aROI.rgbcolor;
                            newROI.opacity = aROI.opacity;
                            
                            [newROI setTexture: t width: imageWidth height: imageHeight];
                            [plainDict setObject: newROI forKey: [aROI name]];
                        }
                        else
                            NSLog( @"***** not enough memory : pointsROIAtX - OrthogonalMPRController");
                    }
                    
                    ROI *p = [plainDict objectForKey: [aROI name]];
                    
                    if( p)
                    {
                        unsigned char* destPtr = [p textureBuffer];
                        unsigned char* srcPtr = [aROI textureBuffer];
                        int sliceIndex = (sign>0)? (long)[[originalView dcmPixList] count]-1 -i : i; // i is slice number
                        
                        destPtr += sliceIndex * imageWidth + aROI.textureUpLeftCornerY;
                        srcPtr += (x - aROI.textureUpLeftCornerX);
                        
                        int c = aROI.textureHeight;
                        int w = aROI.textureWidth;
                        while( c-- > 0)
                        {
                            *(destPtr + c) = *(srcPtr + c * w);
                        }
                    }
                }
            }
		}
	}
    
    for( NSString *key in plainDict)
    {
        ROI *r = [plainDict objectForKey: key];
        
        [r reduceTextureIfPossible];
        
        [roisAtX addObject: r];
    }
	
	return roisAtX;
}

- (NSMutableArray*) pointsROIAtY: (long) y
{
    NSMutableDictionary *plainDict = [NSMutableDictionary dictionary];
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtY = [NSMutableArray array];

    int imageWidth = [[[xReslicedView pixList] lastObject] pwidth];
    int imageHeight = [[[xReslicedView pixList] lastObject] pheight];
    
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
					ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[xReslicedView pixelSpacingX] :[xReslicedView pixelSpacingY] :NSMakePoint( [xReslicedView origin].x, [xReslicedView origin].y)] autorelease];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] x];
					long sliceIndex = (sign>0)? (long)[[originalView dcmPixList] count]-1 -i : i; // i is slice number
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
            
            if( [aROI type] == tPlain)
            {
                if( y >= aROI.textureUpLeftCornerY && y < aROI.textureDownRightCornerY)
                {
                    if( [plainDict objectForKey: [aROI name]] == nil)
                    {
                        unsigned char* t = calloc( imageWidth * imageHeight, sizeof(unsigned char));
                        
                        if( t)
                        {
                            ROI *newROI = [[[ROI alloc] initWithType: tPlain :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
                            
                            newROI.name = [aROI name];
                            newROI.thickness = aROI.thickness;
                            newROI.rgbcolor = aROI.rgbcolor;
                            newROI.opacity = aROI.opacity;
                            
                            [newROI setTexture: t width: imageWidth height: imageHeight];
                            [plainDict setObject: newROI forKey: [aROI name]];
                        }
                        else
                            NSLog( @"***** not enough memory : pointsROIAtX - OrthogonalMPRController");
                    }
                    
                    ROI *p = [plainDict objectForKey: [aROI name]];
                    
                    if( p)
                    {
                        unsigned char* destPtr = [p textureBuffer];
                        unsigned char* srcPtr = [aROI textureBuffer];
                        int sliceIndex = (sign>0)? (long)[[originalView dcmPixList] count]-1 -i : i; // i is slice number
                        
                        destPtr += sliceIndex*imageWidth + aROI.textureUpLeftCornerX;
                        srcPtr += (y - aROI.textureUpLeftCornerY)*aROI.textureWidth;
                        
                        int c = aROI.textureWidth;
                        while( c-- > 0)
                        {
                            *(destPtr + c) = *(srcPtr + c);
                        }
                    }
                }
            }
		}
	}
    
	for( NSString *key in plainDict)
    {
        ROI *r = [plainDict objectForKey: key];
        
        [r reduceTextureIfPossible];
        
        [roisAtY addObject: r];
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

- (void) loadROIonReslicedViews: (long) x : (long) y
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
			contextual =  [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)] autorelease];
			NSMenuItem *item;
			//Menu titles
			NSArray *titles = [NSArray arrayWithObjects:NSLocalizedString(@"Contrast", nil),
														NSLocalizedString(@"Move", nil), 
														NSLocalizedString(@"Magnify", nil), 
														NSLocalizedString(@"Rotate", nil), 
														NSLocalizedString(@"Scroll", nil), 
														NSLocalizedString(@"Length", nil), 
														NSLocalizedString(@"Oval", nil),
														NSLocalizedString(@"Angle", nil),
														NSLocalizedString(@"Point", nil),
														NSLocalizedString(@"Cross", nil), nil];
			//Image Names
			NSArray *images = [NSArray arrayWithObjects: @"WLWW", 
															@"Move", 
															@"Zoom", 			 
															@"Rotate",  
															@"Stack", 
															@"Length",
															@"Oval",
															@"Angle",
															@"Point",
															@"Cross",
															 nil];	// DO NOT LOCALIZE THIS LINE ! -> filenames !
			
			NSArray *tagIndexes = [NSArray arrayWithObjects:[NSNumber numberWithInt:0],
															[NSNumber numberWithInt:1],
															[NSNumber numberWithInt:2],
															[NSNumber numberWithInt:3],
															[NSNumber numberWithInt:4],
															[NSNumber numberWithInt:5],
															[NSNumber numberWithInt:9],
															[NSNumber numberWithInt:12],
															[NSNumber numberWithInt:19],
															[NSNumber numberWithInt:8],
															nil];
															
			NSEnumerator *enumerator2 = [images objectEnumerator];
			NSEnumerator *enumerator3 = [tagIndexes objectEnumerator];
			NSString *title;
			NSString *image;
			NSNumber *tag;
			int i = 0;
			
			for (title in titles)
            {
				image = [enumerator2 nextObject];
				tag = [enumerator3 nextObject];
				item = [[[NSMenuItem alloc] initWithTitle: title action: @selector(changeTool:) keyEquivalent:@""] autorelease];
				[item setTag:[tag intValue]];
				//[item setTarget:self];
				[item setImage:[NSImage imageNamed:image]];
                [[item image] setSize:ToolsMenuIconSize];
				[contextual addItem:item];
			}
			
			[contextual addItem:[NSMenuItem separatorItem]];
			
			/******************* WW/WL menu items **********************/
			NSMenu *menu = [[[[AppController sharedAppController] wlwwMenu] copy] autorelease];
			item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Window Width & Level", nil) action: nil keyEquivalent:@""] autorelease];
			[item setSubmenu:menu];
			[contextual addItem:item];
			
			[contextual addItem:[NSMenuItem separatorItem]];
			
			/************* window resize Menu ****************/
			
			
			NSMenu *submenu =  [[[NSMenu alloc] initWithTitle:@"Resize window"] autorelease];
			
			NSArray *resizeWindowArray = [NSArray arrayWithObjects:@"25%", @"50%", @"100%", @"200%", @"300%", @"iPod Video", nil];
			i = 0;
			NSString	*titleMenu;
			for (titleMenu in resizeWindowArray) {
				int tag = i++;
				item = [[[NSMenuItem alloc] initWithTitle:titleMenu action: @selector(resizeWindow:) keyEquivalent:@""] autorelease];
				[item setTag:tag];
				[submenu addItem:item];
			}
			
			item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Resize window", nil) action: nil keyEquivalent:@""] autorelease];
			[item setSubmenu:submenu];
			[contextual addItem:item];
			
			[contextual addItem:[NSMenuItem separatorItem]];
			
			item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No Rescale Size (100%)", nil) action: @selector(actualSize:) keyEquivalent:@""] autorelease];
			[contextual addItem:item];
			
			item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Actual size", nil) action: @selector(realSize:) keyEquivalent:@""] autorelease];
			[contextual addItem:item];
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
	
	return contextual;
}

- (IBAction) flipVertical: (id)sender{
	BOOL flipped = [sender yFlipped];
	[originalView setYFlipped:flipped];
	[xReslicedView setYFlipped:flipped];
	[yReslicedView setYFlipped:flipped];
}

- (IBAction) flipHorizontal: (id)sender{
   if (![sender isEqual:yReslicedView]) {
		BOOL flipped = [sender xFlipped];
		[originalView setXFlipped:flipped];
		[xReslicedView setXFlipped:flipped];
   }
}


@end
