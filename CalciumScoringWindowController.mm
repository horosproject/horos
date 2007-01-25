//
//  CalciumScoringWindowController.mm
//  OsiriX
//
//  Created by Lance Pysher on 1/25/07.
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

/*************************************************************
Manages the Window for creating Calcium Scoring ROIs
***************************************************************/

#import "CalciumScoringWindowController.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"

#import "ITKSegmentation3DController.h"

enum ctTypes {ElectronCTType, MultiSliceCTType};
@implementation CalciumScoringWindowController

- (id)initWithViewer:(ViewerController *)viewer{
	if (self = [super initWithWindowNibName:@"CalciumScoring"]) {
		_viewer = viewer;
		[self setUpperThreshold:1500];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[self setCtType:[[userDefaults objectForKey:@"CalciumScoreCTType"] intValue]];
		[self setRoiName:NSLocalizedString(@"Left Coronary Artery", nil)];
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(mouseViewerDown:)
				   name: @"mouseDown"
				 object: nil];
				 
		
		[nc addObserver: self
				selector: @selector(drawStartingPoint:)
				   name: @"PLUGINdrawObjects"
				 object: nil];
	}
	return self;
}

- (void)dealloc{
	[_rois release];
	[_roiName release];
	
	[_startingPointPixelPosition release];
	[_startingPointWorldPosition release];
	[_startingPointValue release];
	[super dealloc];
}

- (int)ctType{
	return _ctType;
}

- (void)setCtType:(int)ctType{
	_ctType = ctType;
	if (_ctType == ElectronCTType)
		[self setLowerThreshold:130];
	if (_ctType == MultiSliceCTType) 
		[self setLowerThreshold:90];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_ctType] forKey:@"CalciumScoreCTType"];
}

- (int)lowerThreshold{
	return _lowerThreshold;
}
- (void)setLowerThreshold:(int)lowerThreshold{
	_lowerThreshold = lowerThreshold;
}
- (int)upperThreshold{
	return _upperThreshold;
}

- (void)setUpperThreshold:(int)upperThreshold{
	_upperThreshold = upperThreshold;
}
- (NSMutableArray *)rois{
	return _rois;
}
- (void)setRois:(NSMutableArray *)rois{
	[_rois release];
	_rois = [rois retain];
}

- (NSString *)roiName{
	return _roiName;
}

- (void)setRoiName:(NSString *)roiName{
	[_roiName release];
	_roiName = [roiName retain];
}

- (void) mouseViewerDown:(NSNotification*) note
{
	if([note object] == _viewer)
	{
		int xpx, ypx, zpx; // coordinate in pixels
		float xmm, ymm, zmm; // coordinate in millimeters
		
		xpx = [[[note userInfo] objectForKey:@"X"] intValue];
		ypx = [[[note userInfo] objectForKey:@"Y"] intValue];
		zpx = [[_viewer imageView] curImage];
		
		float location[3];
		[[[_viewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location];
		xmm = location[0];
		ymm = location[1];
		zmm = location[2];
		
		[self setStartingPointPixelPosition:[NSString stringWithFormat:NSLocalizedString(@"px:\t\tx:%d y:%d", 0L), xpx, ypx]];
		[self setStartingPointWorldPosition:[NSString stringWithFormat:NSLocalizedString(@"mm:\t\tx:%2.2f y:%2.2f z:%2.2f", 0L), xmm, ymm, zmm]];
		[self setStartingPointValue:[NSString stringWithFormat:NSLocalizedString(@"value:\t%2.2f", 0L), [[[_viewer imageView] curDCM] getPixelValueX: xpx Y:ypx]]];
		_startingPoint = NSMakePoint(xpx, ypx);
		
		//[self preview: self];
	}
}

- (void) drawStartingPoint:(NSNotification*) note
{
	if([note object] == [_viewer imageView])
	{
		if( _startingPoint.x != 0 && _startingPoint.y != 0)
		{
			NSDictionary	*userInfo = [note userInfo];
			
			glColor3f (0.0f, 1.0f, 0.5f);
			glLineWidth(2.0);
			glBegin(GL_LINES);
			
			float crossx, crossy, scaleValue = [[userInfo valueForKey:@"scaleValue"] floatValue];
			
			crossx = _startingPoint.x - [[userInfo valueForKey:@"offsetx"] floatValue];
			crossy = _startingPoint.y - [[userInfo valueForKey:@"offsety"] floatValue];
			
			glVertex2f( scaleValue * (crossx - 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx - 5), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 5), scaleValue*(crossy));
			
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-40));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+40));
			glEnd();
		}
	}
}

-(NSString *)startingPointPixelPosition{
	return _startingPointPixelPosition;
}

- (void)setStartingPointPixelPosition:(NSString *)position{
	[_startingPointPixelPosition release];
	_startingPointPixelPosition  = [position retain];
}

-(NSString *)startingPointWorldPosition{
	return _startingPointWorldPosition;
}

- (void)setStartingPointWorldPosition:(NSString *)position{
	[_startingPointWorldPosition release];
	_startingPointWorldPosition = [position retain];
}

-(NSString *)startingPointValue{
	return _startingPointValue;
}

- (void)setStartingPointValue:(NSString *)value{
	[_startingPointValue release];
	_startingPointValue = [value retain];
}

-(IBAction) preview:(id) sender
{
	BOOL parametersProvided = YES;
	int p;
	
	[_viewer roiDeleteWithName:@"Segmentation Preview"];
	
	/*
	for(p=0;p<[params numberOfRows]; p++)
	{
		parametersProvided = parametersProvided && (![[[params cellAtRow:p column:0] stringValue] isEqualToString:@""]);
	}
	
	if (!parametersProvided)
	{
		return;
	}
	
	if ( startingPoint.x == 0 && startingPoint.y == 0)
	{
		return;
	}

	long				slice;
	
	slice = [[viewer imageView] curImage];
	
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[viewer pixList] :[viewer volumePtr] :slice];
	if( itk)
	{
		// an array for the parameters
		int algo = [[algorithmPopup selectedItem] tag];
		int parametersCount = [[parameters objectAtIndex:algo] count];
		NSMutableArray *parametersArray = [[NSMutableArray alloc] initWithCapacity:parametersCount];
		int i;
		for(i=0; i<parametersCount; i++)
		{
			[parametersArray addObject:[NSNumber numberWithFloat:[[params cellAtRow:i column:0] floatValue]]];
		}
				
		[itk regionGrowing3D	: viewer
								: 0L
								: slice
								: startingPoint
								: algo //[[params cellAtIndex: 1] floatValue]
								: parametersArray //[[params cellAtIndex: 2] floatValue]
								: [[pixelsSet cellWithTag:0] state]==NSOnState
								: [[pixelsValue cellWithTag:0] floatValue]
								: [[pixelsSet cellWithTag:1] state]==NSOnState
								: [[pixelsValue cellWithTag:1] floatValue]
								: [[outputROIType selectedCell] tag]
								: ((long)[roiResolution maxValue] + 1) - [roiResolution intValue]
								: @"Segmentation Preview"];
		
		[itk release];
	}
	*/
}


@end
