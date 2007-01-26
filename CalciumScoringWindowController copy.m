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
#import "ITKSegmentation3D.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"



#import "CalciumScoringWindowController.h"


enum ctTypes {ElectronCTType, MultiSliceCTType};
@implementation CalciumScoringWindowController

- (id)initWithViewer:(ViewerController *)viewer{
	if (self = [super initWithWindowNibName:@"CalciumScoring"]) {
		_viewer = viewer;
		[self setUpperThreshold:1500];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[self setCtType:[[userDefaults objectForKey:@"CalciumScoreCTType"] intValue]];
		[self setRoiName:NSLocalizedString(@"Left Coronary Artery", nil)];
		_rois = [[NSMutableSet alloc] init];
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
				 
		[nc addObserver: self
				selector: @selector(removeROI:)
				   name:  @"removeROI"
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
- (NSMutableSet *)rois{
	return _rois;
}
- (void)setRois:(NSMutableSet *)rois{
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

- (void)removeROI:(NSNotification*) note{
	[_rois removeObject:[note object]];
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
		
		[self preview: self];
		
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

-(IBAction) preview:(id) sender {
	[self computeROIsWithName:@"Segmentation Preview" addROIs:NO];
}

-(IBAction) compute:(id) sender {
	[self computeROIsWithName:_roiName addROIs:YES];
}


- (void)computeROIsWithName:(NSString *)name addROIs:(BOOL)addROIs;
{

	int p;	
	[_viewer roiDeleteWithName:@"Segmentation Preview"];
	
	
	
	
	if ( _startingPoint.x == 0 && _startingPoint.y == 0)
	{
		return;
	}
	
	long slice = [[_viewer imageView] curImage];
	
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[_viewer pixList] :[_viewer volumePtr] :slice];
	if( itk)
	{


		NSArray *parametersArray = [NSArray arrayWithObjects:
					[NSNumber numberWithInt:_lowerThreshold],
					[NSNumber numberWithInt:_upperThreshold],
					nil];
						
		[itk regionGrowing3D	: _viewer
								: 0L
								: slice
								: _startingPoint
								: 1  //threshold upper and lower limits type
								: parametersArray  // parameter values
								: 0 // next for are used for setting pixels
								: 0
								: 0
								: 0
								: 20 // Brush ROI
								: 0.9 // ROI resolution medium high
								: name];
		
		[itk release];
	}
	
	NSArray *roiList = [_viewer roisWithName:name];
	NSEnumerator *enumerator = [roiList objectEnumerator];
	ROI *roi ;
	while (roi = [enumerator nextObject]) {
		[roi setDisplayCalciumScoring:YES];
		if (addROIs)
			[_rois addObject:roi];
	}
	
	if (addROIs)
		[self updateTotals];
}

- (void)updateTotals{
	float totalScore = 0.0;
	float totalMass = 0.0;
	float totalVolume = 0.0;
	NSEnumerator *enumerator = [_rois objectEnumerator];
	ROI *roi;
	while (roi = [enumerator nextObject]) {
		totalScore += [roi calciumScore];
		totalMass += [roi calciumMass];
		totalVolume += [roi calciumVolume];
	}
	
	[self setTotalCalciumScore:totalScore];
	[self setTotalCalciumMass:totalMass];
	[self setTotalCalciumVolume:totalVolume];
}

- (float)totalCalciumScore{
	return _totalCalciumScore;
}
- (float)totalCalciumMass{
	return _totalCalciumMass;
}
- (float)totalCalciumVolume{
	return _totalCalciumVolume;
}

- (void)setTotalCalciumScore: (float)score{
	_totalCalciumScore = score;
}
- (void)setTotalCalciumMass: (float)mass{
	_totalCalciumMass = mass;
}
- (void)setTotalCalciumVolume: (float)volume{
	_totalCalciumVolume = volume;
}





@end
