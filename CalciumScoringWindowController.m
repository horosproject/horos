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
	
		_rois = [[NSMutableSet alloc] init];
		_vesselNames = [[NSArray arrayWithObjects:NSLocalizedString(@"Left Coronary Artery", nil),
														NSLocalizedString(@"Left Anterior Descending Artery", nil),
														NSLocalizedString(@"Left Circumflex Artery", nil),
														NSLocalizedString(@"Right Coronary Artery", nil),
														nil] retain];
		
		_vessels = [[NSMutableArray alloc] init];
		NSEnumerator *enumerator = [_vesselNames objectEnumerator];
		NSString *name;
		while (name = [enumerator nextObject]) {
			[(NSMutableArray *)_vessels addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: name, @"vesselName",
															[NSNumber numberWithFloat:0.0], @"score",
															[NSNumber numberWithFloat:0.0], @"mass",
															[NSNumber numberWithFloat:0.0], @"volume",
															nil]];
		}
		
		[(NSMutableArray *)_vessels addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"Total", nil), @"vesselName",
															[NSNumber numberWithFloat:0.0], @"score",
															[NSNumber numberWithFloat:0.0], @"mass",
															[NSNumber numberWithFloat:0.0], @"volume",
															nil]];
															
									
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
	[_vessels release];
	[_vesselNames release];
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
	[self updateTotals];
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
	if (![_vesselNames containsObject:roiName]) {
		NSArray *vesselNames = [_vesselNames arrayByAddingObject:roiName];
		[self setVesselNames:vesselNames];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"vesselName like %@", roiName];
		NSArray *filteredVessels = [_vessels filteredArrayUsingPredicate:predicate];
		if ([filteredVessels count] == 0) {
			NSMutableArray *vessels = [NSMutableArray arrayWithArray:_vessels];
			[vessels insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: roiName, @"vesselName",
															[NSNumber numberWithFloat:0.0], @"score",
															[NSNumber numberWithFloat:0.0], @"mass",
															[NSNumber numberWithFloat:0.0], @"volume",
															nil]
			atIndex:[vessels count] - 1];
			[self setVessels:vessels];
		}
		
	}
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
		
		[self compute: self];
		
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

- (IBAction)saveDocument: (id)sender{
	// save ROI as DICOM PDF
	NSLog(@"Save Calcium Score");
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
	NSEnumerator *vesselEnumerator = [_vessels objectEnumerator];
	NSMutableDictionary *vessel;
	while (vessel = [vesselEnumerator nextObject]) {
		NSString *vesselName = [vessel objectForKey:@"vesselName"];
		//NSLog(@"vessel: %@", vesselName);
		if ([vesselName isEqualToString:NSLocalizedString(@"Total", nil)]) {
			[vessel setValue:[NSNumber numberWithFloat:totalScore] forKey:@"score"];
			[vessel setValue:[NSNumber numberWithFloat:totalMass] forKey:@"mass"];
			[vessel setValue:[NSNumber numberWithFloat:totalVolume] forKey:@"volume"];
			break;
		}
			
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like %@", vesselName];
		NSArray *filteredROIs = [[_rois allObjects] filteredArrayUsingPredicate:predicate];
		NSEnumerator *enumerator = [filteredROIs objectEnumerator];
		ROI *roi;
		float segmentScore = 0.0;
		float segmentMass = 0.0;
		float segmentVolume = 0.0;
		while (roi = [enumerator nextObject]) {
			//NSLog(@"roi: %@", [roi name]);
			[roi setCalciumThreshold:_lowerThreshold];
			totalScore += [roi calciumScore];
			totalMass += [roi calciumMass];
			totalVolume += [roi calciumVolume];
			segmentScore += [roi calciumScore];
			segmentMass += [roi calciumMass];
			segmentVolume += [roi calciumVolume];
		}
		[vessel setValue:[NSNumber numberWithFloat:segmentScore] forKey:@"score"];
		[vessel setValue:[NSNumber numberWithFloat:segmentMass] forKey:@"mass"];
		[vessel setValue:[NSNumber numberWithFloat:segmentVolume] forKey:@"volume"];
		[self setTotalCalciumScore:totalScore];
		[self setTotalCalciumMass:totalMass];
		[self setTotalCalciumVolume:totalVolume];
	}
}

//Total Calcium.

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

- (NSArray *)vessels{
	return _vessels;
}
- (void)setVessels:(NSArray *)vessels{
	[_vessels release];
	_vessels = [vessels retain];
}

- (NSArray *)vesselNames{
	return _vesselNames;
}

- (void)setVesselNames:(NSArray *)names{
	[_vesselNames release];
	_vesselNames = [names retain];
}

// for printing and PDF creation
- (NSString *)institution{
	return [[_viewer currentStudy] valueForKey:@"institutionName"];
}
- (NSString *)patientID{
	return [[_viewer currentStudy] valueForKey:@"patientID"];
}
- (NSDate *)studyDate{
	return [[_viewer currentStudy] valueForKey:@"date"];
}
- (NSString *)patientsName{
	return [[_viewer currentStudy] valueForKey:@"name"];
}
- (NSString *)patientsSex{
	return [[_viewer currentStudy] valueForKey:@"patientSex"];
}
- (NSString *)patientsAge{
	return nil;
}
- (NSDate *)patientsDOB{
	return [[_viewer currentStudy] valueForKey:@"dateOfBirth"];
}







@end
